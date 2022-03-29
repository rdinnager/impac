
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

Dmitry Bogdanov (vectorized by T. Michael Keesey), Agnello Picorelli,
Kamil S. Jaron, Emily Willoughby, Steven Traver, Sharon Wegner-Larsen,
Ingo Braasch, Tasman Dixon, FJDegrange, Frank Denota, Andy Wilson, Matt
Crook, Jose Carlos Arenas-Monroy, Jonathan Lawley, Iain Reid, Henry
Lydecker, Unknown (photo), John E. McCormack, Michael G. Harvey, Brant
C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield &
T. Michael Keesey, Jagged Fang Designs, FunkMonk, Scott Hartman, Nobu
Tamura (vectorized by T. Michael Keesey), Alexandre Vong, Mareike C.
Janiak, Hugo Gruson, Gabriela Palomo-Munoz, Margot Michaud, Felix Vaux,
Ray Simpson (vectorized by T. Michael Keesey), Noah Schlottman, photo by
Martin V. Sørensen, C. Camilo Julián-Caballero, Karkemish (vectorized by
T. Michael Keesey), Yan Wong, Kent Elson Sorgon, T. Michael Keesey
(after Mivart), Keith Murdock (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Zimices, Jiekun He, Markus A. Grohme,
James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis
Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey),
Alexandra van der Geer, Ferran Sayol, Cesar Julian, Sarah Werning,
Christoph Schomburg, Alexander Schmidt-Lebuhn, Lily Hughes, Gareth
Monger, S.Martini, Chris huh, Shyamal, Johan Lindgren, Michael W.
Caldwell, Takuya Konishi, Luis M. Chiappe, Rebecca Groom, Oliver
Griffith, Noah Schlottman, photo from National Science Foundation -
Turbellarian Taxonomic Database, Andrew A. Farke, Walter Vladimir,
Ignacio Contreras, Mathilde Cordellier, Ellen Edmonson and Hugh Chrisp
(vectorized by T. Michael Keesey), Birgit Lang, Lukasiniho, T. Michael
Keesey (after Marek Velechovský), Crystal Maier, Collin Gross, Mateus
Zica (modified by T. Michael Keesey), Verdilak, Becky Barnes, Ghedoghedo
(vectorized by T. Michael Keesey), Griensteidl and T. Michael Keesey, B.
Duygu Özpolat, Mykle Hoban, Pete Buchholz, T. Michael Keesey, Charles
Doolittle Walcott (vectorized by T. Michael Keesey), Ben Liebeskind,
Falconaumanni and T. Michael Keesey, Tracy A. Heath, Xavier
Giroux-Bougard, Owen Jones, Erika Schumacher, Matt Martyniuk (modified
by Serenchia), David Orr, Mette Aumala, Alex Slavenko, Jimmy Bernot,
Daniel Jaron, T. Michael Keesey (after Heinrich Harder), Pollyanna von
Knorring and T. Michael Keesey, Amanda Katzer, James R. Spotila and Ray
Chatterji, Anthony Caravaggi, A. R. McCulloch (vectorized by T. Michael
Keesey), Mali’o Kodis, photograph by Ching
(<http://www.flickr.com/photos/36302473@N03/>), Jerry Oldenettel
(vectorized by T. Michael Keesey), Dean Schnabel, Dave Angelini,
wsnaccad, Robbie N. Cada (vectorized by T. Michael Keesey), Didier
Descouens (vectorized by T. Michael Keesey), Joanna Wolfe, Dmitry
Bogdanov, Craig Dylke, Maija Karala, Diego Fontaneto, Elisabeth A.
Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey),
Michael P. Taylor, Neil Kelley, Taenadoman, Matthew Hooge (vectorized by
T. Michael Keesey), Mathew Wedel, Tyler Greenfield, Tony Ayling
(vectorized by T. Michael Keesey), Tod Robbins, Jaime Headden, modified
by T. Michael Keesey, Carlos Cano-Barbacil, George Edward Lodge, E. R.
Waite & H. M. Hale (vectorized by T. Michael Keesey), Sean McCann, M
Kolmann, Michelle Site, Lukas Panzarin (vectorized by T. Michael
Keesey), terngirl, L. Shyamal, Stanton F. Fink (vectorized by T. Michael
Keesey), Aviceda (photo) & T. Michael Keesey, Maxime Dahirel
(digitisation), Kees van Achterberg et al (doi:
10.3897/BDJ.8.e49017)(original publication), Conty (vectorized by T.
Michael Keesey), Steven Coombs, Mattia Menchetti / Yan Wong, Lafage,
Melissa Ingala, Michael Day, Scott D. Sampson, Mark A. Loewen, Andrew A.
Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L.
Titus, Beth Reinke, Jean-Raphaël Guillaumin (photography) and T. Michael
Keesey (vectorization), Julie Blommaert based on photo by Sofdrakou,
Julio Garza,
\<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\>
(vectorized by T. Michael Keesey), Robert Bruce Horsfall, vectorized by
Zimices, J Levin W (illustration) and T. Michael Keesey (vectorization),
Andrew A. Farke, modified from original by H. Milne Edwards, Yan Wong
from illustration by Jules Richard (1907), Smokeybjb (vectorized by T.
Michael Keesey), Steven Haddock • Jellywatch.org, Matt Celeskey, Konsta
Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist,
Christine Axon, Benjamin Monod-Broca, Todd Marshall, vectorized by
Zimices, Jack Mayer Wood, Matus Valach, Robert Hering, Ieuan Jones, T.
K. Robinson, Smokeybjb, Mike Hanson, G. M. Woodward, Isaure Scavezzoni,
Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette), Scott
Hartman (vectorized by T. Michael Keesey), Ville-Veikko Sinkkonen, .
Original drawing by M. Antón, published in Montoya and Morales 1984.
Vectorized by O. Sanisidro, Roberto Diaz Sibaja, based on Domser,
Michael Scroggie, Tauana J. Cunha, T. Michael Keesey (after A. Y.
Ivantsov), Juan Carlos Jerí, Rene Martin, CNZdenek, Ricardo N. Martinez
& Oscar A. Alcober, Scott Reid, Caleb M. Brown, Chuanixn Yu, Jessica
Rick, Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong),
Tim Bertelink (modified by T. Michael Keesey), Henry Fairfield Osborn,
vectorized by Zimices, Duane Raver (vectorized by T. Michael Keesey),
Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey
(vectorization), E. D. Cope (modified by T. Michael Keesey, Michael P.
Taylor & Matthew J. Wedel), U.S. National Park Service (vectorized by
William Gearty), NASA, Hans Hillewaert, Matt Martyniuk (vectorized by T.
Michael Keesey), Renata F. Martins, Abraão Leite, Obsidian Soul
(vectorized by T. Michael Keesey), Milton Tan, Katie S. Collins, Nobu
Tamura (vectorized by A. Verrière), Chris A. Hamilton, Pearson Scott
Foresman (vectorized by T. Michael Keesey), Robert Gay, Mihai Dragos
(vectorized by T. Michael Keesey), Michael Scroggie, from original
photograph by Gary M. Stolz, USFWS (original photograph in public
domain)., Robert Bruce Horsfall (vectorized by T. Michael Keesey),
Kenneth Lacovara (vectorized by T. Michael Keesey), Stanton F. Fink,
vectorized by Zimices, Chloé Schmidt, Jake Warner

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     607.34366 |    566.330656 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|   2 |      85.63892 |    464.035926 | Agnello Picorelli                                                                                                                                                     |
|   3 |     273.27609 |    193.931047 | Kamil S. Jaron                                                                                                                                                        |
|   4 |     413.99040 |    374.704544 | Emily Willoughby                                                                                                                                                      |
|   5 |     274.91710 |    747.480661 | Steven Traver                                                                                                                                                         |
|   6 |     621.20087 |    331.909193 | Kamil S. Jaron                                                                                                                                                        |
|   7 |     738.39971 |    591.033784 | Sharon Wegner-Larsen                                                                                                                                                  |
|   8 |     104.07287 |    723.950153 | Ingo Braasch                                                                                                                                                          |
|   9 |     721.94201 |     29.169244 | Tasman Dixon                                                                                                                                                          |
|  10 |     474.12657 |    747.738719 | Tasman Dixon                                                                                                                                                          |
|  11 |     449.67045 |    232.318979 | FJDegrange                                                                                                                                                            |
|  12 |     697.22688 |    421.411646 | Frank Denota                                                                                                                                                          |
|  13 |     829.42918 |    467.576615 | Andy Wilson                                                                                                                                                           |
|  14 |     191.34209 |    735.216491 | Matt Crook                                                                                                                                                            |
|  15 |     670.58595 |    222.806007 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  16 |     212.15919 |    100.936711 | Jonathan Lawley                                                                                                                                                       |
|  17 |     587.06322 |    745.420619 | Andy Wilson                                                                                                                                                           |
|  18 |     548.35523 |     62.114573 | Iain Reid                                                                                                                                                             |
|  19 |     194.91028 |    297.318632 | Henry Lydecker                                                                                                                                                        |
|  20 |     738.62962 |    512.643525 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  21 |     110.50291 |    553.678081 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
|  22 |     201.47929 |    562.065466 | Jagged Fang Designs                                                                                                                                                   |
|  23 |     389.41046 |    491.122022 | FunkMonk                                                                                                                                                              |
|  24 |     549.22657 |    487.133879 | Scott Hartman                                                                                                                                                         |
|  25 |     791.77659 |    741.929569 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  26 |     415.43464 |    636.338999 | Alexandre Vong                                                                                                                                                        |
|  27 |     799.02347 |    361.641494 | Mareike C. Janiak                                                                                                                                                     |
|  28 |      56.45235 |    204.841644 | Hugo Gruson                                                                                                                                                           |
|  29 |     962.87985 |    254.891109 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  30 |     302.05194 |    282.246984 | Margot Michaud                                                                                                                                                        |
|  31 |     816.73753 |    110.818592 | Felix Vaux                                                                                                                                                            |
|  32 |     962.11337 |    483.043970 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
|  33 |     855.31169 |    178.126633 | Matt Crook                                                                                                                                                            |
|  34 |     259.89678 |    436.696058 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
|  35 |      81.58439 |    378.848057 | Margot Michaud                                                                                                                                                        |
|  36 |     120.68343 |     36.251565 | C. Camilo Julián-Caballero                                                                                                                                            |
|  37 |     568.01324 |    418.331357 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                           |
|  38 |     368.76783 |    708.386618 | Scott Hartman                                                                                                                                                         |
|  39 |     894.79209 |    315.472336 | Yan Wong                                                                                                                                                              |
|  40 |     706.98851 |    151.729495 | Kent Elson Sorgon                                                                                                                                                     |
|  41 |     948.46944 |    703.262713 | T. Michael Keesey (after Mivart)                                                                                                                                      |
|  42 |     294.73276 |     48.743008 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  43 |     580.39719 |    166.523024 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
|  44 |     510.39435 |    590.077860 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  45 |     896.91975 |    653.527211 | Zimices                                                                                                                                                               |
|  46 |     552.68267 |    667.810418 | Jagged Fang Designs                                                                                                                                                   |
|  47 |     891.40494 |    424.394858 | Scott Hartman                                                                                                                                                         |
|  48 |     160.15984 |    643.865299 | Jiekun He                                                                                                                                                             |
|  49 |     869.45560 |     36.907426 | NA                                                                                                                                                                    |
|  50 |     274.05493 |    603.181088 | Margot Michaud                                                                                                                                                        |
|  51 |     168.03231 |    388.657320 | NA                                                                                                                                                                    |
|  52 |     370.22724 |    556.764225 | Markus A. Grohme                                                                                                                                                      |
|  53 |     791.49338 |    648.521149 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
|  54 |     817.72189 |    560.485817 | Alexandra van der Geer                                                                                                                                                |
|  55 |     421.96658 |    414.528388 | Ferran Sayol                                                                                                                                                          |
|  56 |      86.31191 |     72.749863 | Cesar Julian                                                                                                                                                          |
|  57 |     243.05196 |    527.891596 | Zimices                                                                                                                                                               |
|  58 |     112.75015 |    633.039319 | Sarah Werning                                                                                                                                                         |
|  59 |     195.65983 |    239.105133 | Margot Michaud                                                                                                                                                        |
|  60 |     972.03117 |    106.856754 | Kamil S. Jaron                                                                                                                                                        |
|  61 |     454.13609 |    127.525482 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  62 |     329.81391 |    108.229248 | Zimices                                                                                                                                                               |
|  63 |     906.10414 |    575.791423 | Matt Crook                                                                                                                                                            |
|  64 |     706.75204 |    103.189941 | Scott Hartman                                                                                                                                                         |
|  65 |     122.42117 |    170.460703 | Christoph Schomburg                                                                                                                                                   |
|  66 |     597.47827 |    464.521917 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  67 |      17.17260 |    736.798008 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  68 |      79.60296 |    331.824342 | Lily Hughes                                                                                                                                                           |
|  69 |     759.38210 |    304.429861 | Gareth Monger                                                                                                                                                         |
|  70 |     273.89293 |    229.237930 | S.Martini                                                                                                                                                             |
|  71 |     882.70623 |    776.413983 | Chris huh                                                                                                                                                             |
|  72 |     622.30890 |    630.501914 | Shyamal                                                                                                                                                               |
|  73 |     533.17274 |    204.837127 | Gareth Monger                                                                                                                                                         |
|  74 |     517.78887 |     14.731547 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
|  75 |     437.45113 |    518.657921 | Rebecca Groom                                                                                                                                                         |
|  76 |     712.27804 |    513.293658 | Scott Hartman                                                                                                                                                         |
|  77 |     692.20516 |    661.092134 | Alexandre Vong                                                                                                                                                        |
|  78 |     745.41500 |    204.544562 | Felix Vaux                                                                                                                                                            |
|  79 |     466.54689 |    553.367327 | Scott Hartman                                                                                                                                                         |
|  80 |     694.77051 |    340.464156 | Oliver Griffith                                                                                                                                                       |
|  81 |     358.10834 |    652.257915 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  82 |     426.64115 |     56.205926 | Iain Reid                                                                                                                                                             |
|  83 |     997.92897 |    383.024827 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                             |
|  84 |     279.80409 |    396.925573 | Gareth Monger                                                                                                                                                         |
|  85 |      59.07935 |    669.963103 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  86 |      90.24251 |    782.266633 | Ferran Sayol                                                                                                                                                          |
|  87 |     990.45971 |    329.629951 | NA                                                                                                                                                                    |
|  88 |     697.73116 |    757.960734 | Andrew A. Farke                                                                                                                                                       |
|  89 |     311.31132 |    680.299831 | Walter Vladimir                                                                                                                                                       |
|  90 |     990.71641 |    633.805215 | C. Camilo Julián-Caballero                                                                                                                                            |
|  91 |     462.76395 |    334.338624 | Margot Michaud                                                                                                                                                        |
|  92 |     194.03473 |    272.865670 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  93 |     279.21077 |    355.766710 | Tasman Dixon                                                                                                                                                          |
|  94 |     779.42102 |     71.102847 | Margot Michaud                                                                                                                                                        |
|  95 |     961.39701 |    188.484971 | Matt Crook                                                                                                                                                            |
|  96 |     183.99249 |    171.360457 | Ignacio Contreras                                                                                                                                                     |
|  97 |     624.64547 |    682.701878 | Chris huh                                                                                                                                                             |
|  98 |      59.22719 |    761.244155 | Mathilde Cordellier                                                                                                                                                   |
|  99 |     160.37594 |    191.785447 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 100 |      30.54982 |    581.996378 | Birgit Lang                                                                                                                                                           |
| 101 |     262.84277 |    341.195929 | Matt Crook                                                                                                                                                            |
| 102 |      93.80422 |    106.526985 | Chris huh                                                                                                                                                             |
| 103 |      97.75780 |    263.359445 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 104 |      31.78050 |    479.436060 | Ferran Sayol                                                                                                                                                          |
| 105 |     919.63700 |    390.225447 | NA                                                                                                                                                                    |
| 106 |     527.67519 |    745.293898 | Ferran Sayol                                                                                                                                                          |
| 107 |     846.89840 |    248.024846 | Margot Michaud                                                                                                                                                        |
| 108 |     424.07896 |     18.962459 | Lukasiniho                                                                                                                                                            |
| 109 |     347.93545 |    184.726482 | Mathilde Cordellier                                                                                                                                                   |
| 110 |     385.43600 |    329.368716 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
| 111 |     784.25438 |    158.961339 | Crystal Maier                                                                                                                                                         |
| 112 |     673.54552 |     76.071370 | Margot Michaud                                                                                                                                                        |
| 113 |     861.95724 |     79.557390 | Collin Gross                                                                                                                                                          |
| 114 |     960.42101 |    369.441479 | Gareth Monger                                                                                                                                                         |
| 115 |     690.70341 |    401.635010 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 116 |     656.71564 |    664.975037 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
| 117 |     196.51869 |    457.105427 | Steven Traver                                                                                                                                                         |
| 118 |     682.72131 |    450.786589 | Margot Michaud                                                                                                                                                        |
| 119 |     126.86088 |    754.011446 | Verdilak                                                                                                                                                              |
| 120 |     386.12245 |    743.569368 | NA                                                                                                                                                                    |
| 121 |      25.00264 |    638.439676 | Steven Traver                                                                                                                                                         |
| 122 |     580.15784 |    374.984771 | Felix Vaux                                                                                                                                                            |
| 123 |     383.29286 |     30.760659 | Becky Barnes                                                                                                                                                          |
| 124 |     743.27635 |    434.543227 | Lukasiniho                                                                                                                                                            |
| 125 |     899.34711 |    708.772619 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 126 |    1006.86149 |    577.501118 | Matt Crook                                                                                                                                                            |
| 127 |     460.17785 |    674.431024 | Crystal Maier                                                                                                                                                         |
| 128 |     540.10594 |    555.078893 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 129 |      46.84243 |    535.929486 | Matt Crook                                                                                                                                                            |
| 130 |     276.83749 |     88.317659 | Margot Michaud                                                                                                                                                        |
| 131 |     327.00823 |    394.248153 | B. Duygu Özpolat                                                                                                                                                      |
| 132 |      57.36190 |    127.552440 | Mykle Hoban                                                                                                                                                           |
| 133 |     399.58170 |    774.454217 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 134 |     934.31888 |    534.048798 | Pete Buchholz                                                                                                                                                         |
| 135 |      25.46963 |    399.476569 | Andy Wilson                                                                                                                                                           |
| 136 |     231.38218 |    330.154921 | Collin Gross                                                                                                                                                          |
| 137 |     371.61777 |    252.049566 | T. Michael Keesey                                                                                                                                                     |
| 138 |      75.90338 |    118.815774 | T. Michael Keesey                                                                                                                                                     |
| 139 |      20.82988 |    149.381744 | Matt Crook                                                                                                                                                            |
| 140 |     466.22919 |    530.139380 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 141 |     988.40892 |     37.784276 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                           |
| 142 |     495.84491 |    108.766371 | Ben Liebeskind                                                                                                                                                        |
| 143 |     609.24974 |     86.498568 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 144 |     978.63332 |    458.480816 | Zimices                                                                                                                                                               |
| 145 |     821.80859 |    763.504979 | Tracy A. Heath                                                                                                                                                        |
| 146 |     473.12281 |    721.032511 | Xavier Giroux-Bougard                                                                                                                                                 |
| 147 |     830.72399 |    692.569506 | Owen Jones                                                                                                                                                            |
| 148 |     295.05218 |     12.479349 | Steven Traver                                                                                                                                                         |
| 149 |     926.97450 |    328.039443 | NA                                                                                                                                                                    |
| 150 |     811.13849 |    673.112661 | Erika Schumacher                                                                                                                                                      |
| 151 |     318.03602 |    654.668534 | Gareth Monger                                                                                                                                                         |
| 152 |     995.92437 |    731.694142 | Kamil S. Jaron                                                                                                                                                        |
| 153 |     637.91992 |    516.947144 | Matt Martyniuk (modified by Serenchia)                                                                                                                                |
| 154 |     762.83111 |     19.171695 | David Orr                                                                                                                                                             |
| 155 |     181.45322 |    488.042755 | T. Michael Keesey                                                                                                                                                     |
| 156 |      95.27982 |     13.764483 | Scott Hartman                                                                                                                                                         |
| 157 |     733.50822 |    400.605547 | Mette Aumala                                                                                                                                                          |
| 158 |     356.14320 |     10.614963 | Steven Traver                                                                                                                                                         |
| 159 |     320.04427 |    432.134508 | Alex Slavenko                                                                                                                                                         |
| 160 |      17.48698 |    262.783325 | Jimmy Bernot                                                                                                                                                          |
| 161 |      48.72393 |     31.681822 | Matt Crook                                                                                                                                                            |
| 162 |     127.15168 |    608.303331 | Daniel Jaron                                                                                                                                                          |
| 163 |     610.11808 |    595.134587 | Jagged Fang Designs                                                                                                                                                   |
| 164 |     398.15385 |    664.526043 | T. Michael Keesey (after Heinrich Harder)                                                                                                                             |
| 165 |     958.77878 |     13.324492 | Matt Crook                                                                                                                                                            |
| 166 |     667.07933 |    527.195502 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 167 |     507.85196 |    640.434985 | Amanda Katzer                                                                                                                                                         |
| 168 |     400.19740 |    288.939587 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 169 |     557.39852 |    275.016563 | Anthony Caravaggi                                                                                                                                                     |
| 170 |      62.93346 |    294.340371 | Zimices                                                                                                                                                               |
| 171 |     344.28361 |    251.049947 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                     |
| 172 |     656.19501 |    119.966892 | Gareth Monger                                                                                                                                                         |
| 173 |     681.24189 |    722.662508 | Jagged Fang Designs                                                                                                                                                   |
| 174 |     533.52498 |    356.239322 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                                      |
| 175 |     578.92569 |    778.716028 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 176 |     656.76246 |     23.500076 | Jagged Fang Designs                                                                                                                                                   |
| 177 |     767.28858 |    687.566076 | Dean Schnabel                                                                                                                                                         |
| 178 |     799.11923 |    318.146300 | NA                                                                                                                                                                    |
| 179 |     975.21860 |    429.336839 | Ferran Sayol                                                                                                                                                          |
| 180 |     637.68435 |     87.683500 | Crystal Maier                                                                                                                                                         |
| 181 |     677.23573 |    373.164285 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 182 |     793.94552 |    621.032537 | Ferran Sayol                                                                                                                                                          |
| 183 |     639.99937 |    402.606432 | Zimices                                                                                                                                                               |
| 184 |     694.18844 |    310.922326 | Jagged Fang Designs                                                                                                                                                   |
| 185 |     759.35402 |    557.991860 | Andrew A. Farke                                                                                                                                                       |
| 186 |     827.97228 |    522.649552 | Amanda Katzer                                                                                                                                                         |
| 187 |      24.72792 |    288.367083 | Matt Crook                                                                                                                                                            |
| 188 |     497.12713 |    785.491461 | Pete Buchholz                                                                                                                                                         |
| 189 |     713.10697 |    287.852861 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 190 |     732.82754 |    669.673241 | Sharon Wegner-Larsen                                                                                                                                                  |
| 191 |     878.57322 |    580.179029 | Dave Angelini                                                                                                                                                         |
| 192 |     584.13329 |    649.433600 | wsnaccad                                                                                                                                                              |
| 193 |     507.25844 |    332.292682 | Matt Crook                                                                                                                                                            |
| 194 |     673.34188 |    293.007094 | T. Michael Keesey                                                                                                                                                     |
| 195 |     538.95694 |    474.017153 | Scott Hartman                                                                                                                                                         |
| 196 |     929.86756 |    449.527492 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 197 |     941.25916 |    404.071258 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 198 |     192.10820 |     13.195660 | Jagged Fang Designs                                                                                                                                                   |
| 199 |     855.35444 |    103.086424 | Andy Wilson                                                                                                                                                           |
| 200 |     482.87538 |    624.570854 | Joanna Wolfe                                                                                                                                                          |
| 201 |      16.28991 |    113.732828 | Scott Hartman                                                                                                                                                         |
| 202 |      16.37182 |    610.687423 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 203 |     210.15980 |    781.403349 | Dmitry Bogdanov                                                                                                                                                       |
| 204 |     468.38815 |    710.849608 | Craig Dylke                                                                                                                                                           |
| 205 |     551.61577 |    634.739507 | Ferran Sayol                                                                                                                                                          |
| 206 |     495.70595 |    700.595038 | NA                                                                                                                                                                    |
| 207 |    1002.04051 |    215.185581 | Matt Crook                                                                                                                                                            |
| 208 |     627.99558 |    781.652947 | Tasman Dixon                                                                                                                                                          |
| 209 |     446.45126 |    711.581428 | Zimices                                                                                                                                                               |
| 210 |     951.24392 |     40.987952 | Jagged Fang Designs                                                                                                                                                   |
| 211 |     825.80547 |    615.431158 | Dave Angelini                                                                                                                                                         |
| 212 |     984.67211 |    560.210527 | Maija Karala                                                                                                                                                          |
| 213 |     575.19250 |    597.290351 | Zimices                                                                                                                                                               |
| 214 |      10.60040 |     33.811133 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 215 |      62.42716 |    698.171884 | NA                                                                                                                                                                    |
| 216 |     603.23018 |     40.519461 | Michael P. Taylor                                                                                                                                                     |
| 217 |     762.10615 |    620.590540 | Matt Crook                                                                                                                                                            |
| 218 |     914.31138 |    700.978826 | Ferran Sayol                                                                                                                                                          |
| 219 |     477.79400 |    428.977445 | Matt Crook                                                                                                                                                            |
| 220 |     505.28768 |    381.392336 | Neil Kelley                                                                                                                                                           |
| 221 |     588.32599 |    522.638774 | T. Michael Keesey                                                                                                                                                     |
| 222 |     393.31926 |    449.775918 | Lukasiniho                                                                                                                                                            |
| 223 |     759.05525 |    421.207822 | Zimices                                                                                                                                                               |
| 224 |     650.74998 |     53.295983 | Emily Willoughby                                                                                                                                                      |
| 225 |      96.71285 |    694.313109 | Margot Michaud                                                                                                                                                        |
| 226 |     770.56770 |    189.882417 | Zimices                                                                                                                                                               |
| 227 |     987.99044 |    780.577867 | Sarah Werning                                                                                                                                                         |
| 228 |     673.55396 |    556.873174 | Felix Vaux                                                                                                                                                            |
| 229 |     528.19105 |    533.545354 | T. Michael Keesey                                                                                                                                                     |
| 230 |     721.60013 |    177.074494 | Taenadoman                                                                                                                                                            |
| 231 |     618.68614 |    508.622286 | Iain Reid                                                                                                                                                             |
| 232 |      18.45660 |    532.367711 | Zimices                                                                                                                                                               |
| 233 |      47.24340 |      9.829136 | Alex Slavenko                                                                                                                                                         |
| 234 |     360.66516 |    398.147316 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
| 235 |     945.14199 |    149.234730 | Ferran Sayol                                                                                                                                                          |
| 236 |     233.47463 |    495.033000 | Mathew Wedel                                                                                                                                                          |
| 237 |     479.33125 |    667.576066 | Tyler Greenfield                                                                                                                                                      |
| 238 |     512.34830 |    147.319731 | Emily Willoughby                                                                                                                                                      |
| 239 |     687.27773 |    275.086625 | Kent Elson Sorgon                                                                                                                                                     |
| 240 |     841.92112 |    314.104498 | FunkMonk                                                                                                                                                              |
| 241 |     216.45065 |    572.945956 | Margot Michaud                                                                                                                                                        |
| 242 |     848.03233 |    670.501918 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 243 |     415.43146 |    586.649232 | Tod Robbins                                                                                                                                                           |
| 244 |     453.56391 |    454.787802 | Sarah Werning                                                                                                                                                         |
| 245 |     627.96489 |    124.811030 | Gareth Monger                                                                                                                                                         |
| 246 |     908.89550 |      7.238116 | Gareth Monger                                                                                                                                                         |
| 247 |     488.89251 |     78.659978 | Zimices                                                                                                                                                               |
| 248 |     708.63431 |    781.929044 | Steven Traver                                                                                                                                                         |
| 249 |     407.15523 |     85.922533 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 250 |     105.59619 |    670.185859 | T. Michael Keesey                                                                                                                                                     |
| 251 |     857.53174 |    123.648981 | Steven Traver                                                                                                                                                         |
| 252 |     236.58283 |     12.448457 | Carlos Cano-Barbacil                                                                                                                                                  |
| 253 |     994.06048 |    706.081382 | Agnello Picorelli                                                                                                                                                     |
| 254 |     629.76026 |    163.266514 | Zimices                                                                                                                                                               |
| 255 |     786.81691 |      3.317768 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 256 |      76.54496 |    147.935362 | George Edward Lodge                                                                                                                                                   |
| 257 |     835.59960 |    299.872204 | Dean Schnabel                                                                                                                                                         |
| 258 |     339.97144 |    531.358410 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                            |
| 259 |     557.77840 |    704.229911 | Steven Traver                                                                                                                                                         |
| 260 |     350.39838 |    579.039278 | Sean McCann                                                                                                                                                           |
| 261 |     140.41527 |    217.899829 | Zimices                                                                                                                                                               |
| 262 |     952.92704 |    334.299111 | Andy Wilson                                                                                                                                                           |
| 263 |     358.22966 |    787.842939 | Rebecca Groom                                                                                                                                                         |
| 264 |     891.04748 |     61.986091 | Mykle Hoban                                                                                                                                                           |
| 265 |     884.34620 |    493.014473 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 266 |     496.16913 |    303.460047 | Markus A. Grohme                                                                                                                                                      |
| 267 |     627.37271 |    533.851506 | M Kolmann                                                                                                                                                             |
| 268 |    1007.22502 |    426.473497 | Michelle Site                                                                                                                                                         |
| 269 |     482.60250 |    519.284098 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                      |
| 270 |     507.01486 |     97.246639 | NA                                                                                                                                                                    |
| 271 |     647.92564 |    645.710273 | Kamil S. Jaron                                                                                                                                                        |
| 272 |     904.38086 |    209.627832 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 273 |    1007.19629 |    293.738155 | Zimices                                                                                                                                                               |
| 274 |     724.20797 |    270.147234 | Jagged Fang Designs                                                                                                                                                   |
| 275 |     371.62574 |    773.700319 | Markus A. Grohme                                                                                                                                                      |
| 276 |     365.69753 |    762.169023 | Gareth Monger                                                                                                                                                         |
| 277 |     802.27815 |    418.836288 | Matt Crook                                                                                                                                                            |
| 278 |      47.67762 |    271.952337 | Andrew A. Farke                                                                                                                                                       |
| 279 |     445.90230 |    616.401209 | Mathilde Cordellier                                                                                                                                                   |
| 280 |     141.26815 |      9.513772 | terngirl                                                                                                                                                              |
| 281 |     190.21326 |    764.947684 | M Kolmann                                                                                                                                                             |
| 282 |     315.94314 |    230.734398 | Christoph Schomburg                                                                                                                                                   |
| 283 |     258.83615 |    148.983894 | Jagged Fang Designs                                                                                                                                                   |
| 284 |     344.78000 |    326.175829 | Andrew A. Farke                                                                                                                                                       |
| 285 |     708.85114 |     78.502878 | Margot Michaud                                                                                                                                                        |
| 286 |     791.97341 |     12.062214 | Gareth Monger                                                                                                                                                         |
| 287 |     423.77644 |    498.548971 | Zimices                                                                                                                                                               |
| 288 |     835.28295 |    506.105091 | Margot Michaud                                                                                                                                                        |
| 289 |     629.22311 |     27.176501 | L. Shyamal                                                                                                                                                            |
| 290 |     366.47574 |    301.691467 | NA                                                                                                                                                                    |
| 291 |     521.73472 |    778.109717 | Steven Traver                                                                                                                                                         |
| 292 |     441.15283 |    736.644106 | Matt Crook                                                                                                                                                            |
| 293 |     991.22085 |    671.167980 | Tasman Dixon                                                                                                                                                          |
| 294 |     967.04121 |     64.277047 | Lukasiniho                                                                                                                                                            |
| 295 |     634.11518 |    449.555582 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 296 |     790.45900 |    439.603012 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 297 |     317.05741 |    316.983933 | Gareth Monger                                                                                                                                                         |
| 298 |     913.30225 |    746.146895 | Aviceda (photo) & T. Michael Keesey                                                                                                                                   |
| 299 |     797.70750 |    592.353661 | Zimices                                                                                                                                                               |
| 300 |     713.59249 |    441.126976 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                            |
| 301 |     262.69404 |     70.406688 | Lukasiniho                                                                                                                                                            |
| 302 |     979.64489 |    660.819338 | Scott Hartman                                                                                                                                                         |
| 303 |     879.64312 |    514.942523 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                           |
| 304 |     669.52607 |    171.623657 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 305 |     741.85995 |    453.268060 | Zimices                                                                                                                                                               |
| 306 |      82.15896 |    299.249622 | Margot Michaud                                                                                                                                                        |
| 307 |     144.84883 |    501.260331 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 308 |     652.41300 |    761.205086 | Yan Wong                                                                                                                                                              |
| 309 |     110.50843 |    421.349837 | Steven Coombs                                                                                                                                                         |
| 310 |     220.57090 |    759.513254 | Kamil S. Jaron                                                                                                                                                        |
| 311 |     775.12555 |    137.931542 | Matt Crook                                                                                                                                                            |
| 312 |      18.74799 |    660.166973 | Sharon Wegner-Larsen                                                                                                                                                  |
| 313 |     465.85293 |    373.702815 | Mattia Menchetti / Yan Wong                                                                                                                                           |
| 314 |     863.21112 |    401.070861 | Margot Michaud                                                                                                                                                        |
| 315 |     151.62680 |    108.065738 | T. Michael Keesey                                                                                                                                                     |
| 316 |     396.18943 |    648.612288 | Jagged Fang Designs                                                                                                                                                   |
| 317 |     191.68465 |    530.460486 | NA                                                                                                                                                                    |
| 318 |     303.13124 |    787.853495 | Jagged Fang Designs                                                                                                                                                   |
| 319 |      68.99061 |    558.112357 | Lafage                                                                                                                                                                |
| 320 |     622.70444 |    194.666118 | Melissa Ingala                                                                                                                                                        |
| 321 |     686.15073 |    705.130748 | Scott Hartman                                                                                                                                                         |
| 322 |     411.13982 |    277.816744 | Birgit Lang                                                                                                                                                           |
| 323 |     818.88210 |    634.075025 | Mathew Wedel                                                                                                                                                          |
| 324 |     501.62678 |    158.111036 | Andrew A. Farke                                                                                                                                                       |
| 325 |    1011.07887 |     81.101781 | Michael Day                                                                                                                                                           |
| 326 |     563.00000 |    244.259108 | Birgit Lang                                                                                                                                                           |
| 327 |     962.27919 |    582.029881 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 328 |     207.39314 |    661.783261 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 329 |     543.60074 |    776.920310 | Steven Traver                                                                                                                                                         |
| 330 |     515.54389 |    415.714891 | Andrew A. Farke                                                                                                                                                       |
| 331 |     505.25564 |    505.412334 | NA                                                                                                                                                                    |
| 332 |    1000.62526 |    523.553033 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 333 |     595.14714 |    381.210862 | Michelle Site                                                                                                                                                         |
| 334 |     639.84546 |    595.280031 | Anthony Caravaggi                                                                                                                                                     |
| 335 |     580.42685 |    308.766547 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 336 |      16.70458 |    423.681169 | Beth Reinke                                                                                                                                                           |
| 337 |     341.21458 |    716.892048 | Mykle Hoban                                                                                                                                                           |
| 338 |     861.93558 |    214.130971 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                           |
| 339 |     365.10152 |    453.302167 | Ferran Sayol                                                                                                                                                          |
| 340 |    1004.03832 |    685.034150 | Julie Blommaert based on photo by Sofdrakou                                                                                                                           |
| 341 |     872.65125 |    749.647065 | Andy Wilson                                                                                                                                                           |
| 342 |     979.08654 |     19.227654 | Julio Garza                                                                                                                                                           |
| 343 |     893.80795 |    241.939104 | Margot Michaud                                                                                                                                                        |
| 344 |     226.63590 |    304.682508 | Jagged Fang Designs                                                                                                                                                   |
| 345 |     712.37496 |    379.465303 | Steven Traver                                                                                                                                                         |
| 346 |     703.48971 |    694.965062 | Margot Michaud                                                                                                                                                        |
| 347 |     838.41477 |     72.312425 | \<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\> (vectorized by T. Michael Keesey)                                          |
| 348 |     176.92915 |    470.756843 | Margot Michaud                                                                                                                                                        |
| 349 |     272.04685 |    696.146622 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 350 |      19.30655 |     88.344522 | NA                                                                                                                                                                    |
| 351 |     221.30883 |    293.681455 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 352 |     380.95373 |    578.936478 | Zimices                                                                                                                                                               |
| 353 |     211.17123 |    256.698442 | Jagged Fang Designs                                                                                                                                                   |
| 354 |     133.04865 |    436.450610 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                                        |
| 355 |     916.88910 |    188.949709 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                           |
| 356 |     212.81671 |    195.908137 | Scott Hartman                                                                                                                                                         |
| 357 |     540.95337 |    463.727669 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
| 358 |     761.72759 |    113.097697 | Felix Vaux                                                                                                                                                            |
| 359 |      35.17009 |    731.778087 | T. Michael Keesey                                                                                                                                                     |
| 360 |     287.58042 |    259.461213 | Ignacio Contreras                                                                                                                                                     |
| 361 |     358.37664 |    144.961495 | Ignacio Contreras                                                                                                                                                     |
| 362 |     825.14448 |    658.436267 | Scott Hartman                                                                                                                                                         |
| 363 |     250.34891 |    251.953620 | Felix Vaux                                                                                                                                                            |
| 364 |     349.58258 |    237.404036 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 365 |     406.80020 |    754.498555 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 366 |     566.50590 |    717.972161 | Cesar Julian                                                                                                                                                          |
| 367 |     495.47626 |     34.197025 | Scott Hartman                                                                                                                                                         |
| 368 |     485.70835 |    449.999719 | Scott Hartman                                                                                                                                                         |
| 369 |     278.87128 |    150.267511 | Gareth Monger                                                                                                                                                         |
| 370 |     974.46295 |    591.916639 | Gareth Monger                                                                                                                                                         |
| 371 |     493.74176 |    438.866525 | NA                                                                                                                                                                    |
| 372 |     367.35616 |    631.069013 | Matt Celeskey                                                                                                                                                         |
| 373 |    1007.67150 |    173.390441 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                 |
| 374 |     540.85447 |     25.315229 | Christine Axon                                                                                                                                                        |
| 375 |     916.23409 |    559.067584 | Andrew A. Farke                                                                                                                                                       |
| 376 |     444.99470 |    540.719176 | NA                                                                                                                                                                    |
| 377 |     801.09615 |    691.756892 | Benjamin Monod-Broca                                                                                                                                                  |
| 378 |     809.13250 |    284.528678 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 379 |     670.37713 |    594.261086 | T. Michael Keesey                                                                                                                                                     |
| 380 |     516.26450 |    793.378947 | Jack Mayer Wood                                                                                                                                                       |
| 381 |     453.96590 |     74.988688 | Christoph Schomburg                                                                                                                                                   |
| 382 |      95.60147 |    411.015041 | Scott Hartman                                                                                                                                                         |
| 383 |     496.59067 |    483.655054 | Matus Valach                                                                                                                                                          |
| 384 |     750.01676 |    323.572138 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 385 |     287.25046 |    652.749101 | Markus A. Grohme                                                                                                                                                      |
| 386 |      13.35944 |    367.461198 | T. Michael Keesey                                                                                                                                                     |
| 387 |     552.45063 |    609.877510 | Andy Wilson                                                                                                                                                           |
| 388 |     148.81283 |    576.941065 | Robert Hering                                                                                                                                                         |
| 389 |     554.15763 |    214.642937 | NA                                                                                                                                                                    |
| 390 |     164.28858 |    780.623406 | Ieuan Jones                                                                                                                                                           |
| 391 |     858.17423 |    617.947886 | Ferran Sayol                                                                                                                                                          |
| 392 |     894.62791 |    542.492821 | T. K. Robinson                                                                                                                                                        |
| 393 |     544.27830 |    530.592221 | Ignacio Contreras                                                                                                                                                     |
| 394 |     759.16029 |     57.874714 | Smokeybjb                                                                                                                                                             |
| 395 |     327.21071 |    136.912680 | Chris huh                                                                                                                                                             |
| 396 |     665.45558 |    499.020044 | Collin Gross                                                                                                                                                          |
| 397 |     233.52094 |    656.026636 | Markus A. Grohme                                                                                                                                                      |
| 398 |     395.13855 |    263.270969 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 399 |     458.28195 |    383.103220 | Mike Hanson                                                                                                                                                           |
| 400 |     510.36288 |    552.692977 | T. Michael Keesey                                                                                                                                                     |
| 401 |     800.28684 |    612.565658 | Jagged Fang Designs                                                                                                                                                   |
| 402 |     365.88014 |    619.319982 | Tasman Dixon                                                                                                                                                          |
| 403 |     776.44142 |    405.116573 | G. M. Woodward                                                                                                                                                        |
| 404 |     835.80136 |     52.080968 | Isaure Scavezzoni                                                                                                                                                     |
| 405 |     937.29248 |      3.232787 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 406 |     999.60453 |    746.959790 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                       |
| 407 |     836.44516 |    153.223419 | Daniel Jaron                                                                                                                                                          |
| 408 |      36.80802 |    316.055054 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 409 |     604.46927 |     28.526566 | NA                                                                                                                                                                    |
| 410 |     658.46417 |    274.248726 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 411 |     268.51519 |     17.435307 | Zimices                                                                                                                                                               |
| 412 |     552.93985 |    371.072114 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                                     |
| 413 |     499.56323 |    764.958218 | T. Michael Keesey                                                                                                                                                     |
| 414 |      18.02341 |    306.937655 | Mette Aumala                                                                                                                                                          |
| 415 |     211.66590 |    612.210808 | NA                                                                                                                                                                    |
| 416 |     328.56180 |    795.980901 | Markus A. Grohme                                                                                                                                                      |
| 417 |     328.71156 |    381.015642 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                       |
| 418 |     909.97306 |    532.260916 | Tasman Dixon                                                                                                                                                          |
| 419 |     949.67178 |    794.056180 | Roberto Diaz Sibaja, based on Domser                                                                                                                                  |
| 420 |     944.61425 |    637.188087 | NA                                                                                                                                                                    |
| 421 |     596.99137 |    701.242083 | Zimices                                                                                                                                                               |
| 422 |     701.92685 |    422.634186 | Michael Scroggie                                                                                                                                                      |
| 423 |     868.44537 |    392.485714 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 424 |     623.33261 |     85.743334 | Ferran Sayol                                                                                                                                                          |
| 425 |    1008.29251 |    246.762346 | Christine Axon                                                                                                                                                        |
| 426 |     586.94859 |     16.119405 | Margot Michaud                                                                                                                                                        |
| 427 |     723.59623 |      9.028141 | Jagged Fang Designs                                                                                                                                                   |
| 428 |     300.24469 |     91.932981 | Andy Wilson                                                                                                                                                           |
| 429 |     372.16889 |    226.707244 | Tracy A. Heath                                                                                                                                                        |
| 430 |     561.74406 |    334.597275 | Scott Hartman                                                                                                                                                         |
| 431 |     752.96656 |    262.391341 | Tauana J. Cunha                                                                                                                                                       |
| 432 |     664.58490 |     36.746690 | Chris huh                                                                                                                                                             |
| 433 |     838.09537 |    288.314026 | Markus A. Grohme                                                                                                                                                      |
| 434 |     908.91885 |     72.950384 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 435 |    1005.46115 |    759.673438 | Jack Mayer Wood                                                                                                                                                       |
| 436 |      54.62689 |    420.936598 | Gareth Monger                                                                                                                                                         |
| 437 |     496.16099 |    315.012024 | Steven Traver                                                                                                                                                         |
| 438 |     326.92426 |    412.660986 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                              |
| 439 |     423.54828 |    388.061555 | Juan Carlos Jerí                                                                                                                                                      |
| 440 |     212.06477 |    582.402122 | Scott Hartman                                                                                                                                                         |
| 441 |     654.48557 |    547.944755 | Margot Michaud                                                                                                                                                        |
| 442 |    1007.33943 |     12.076079 | Rene Martin                                                                                                                                                           |
| 443 |      42.53433 |    612.079029 | T. Michael Keesey                                                                                                                                                     |
| 444 |     452.56994 |    595.560557 | CNZdenek                                                                                                                                                              |
| 445 |     349.27313 |    407.711288 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                |
| 446 |     970.77099 |    523.485220 | Scott Hartman                                                                                                                                                         |
| 447 |     765.12996 |    224.666802 | Gareth Monger                                                                                                                                                         |
| 448 |     556.80125 |    303.407103 | Scott Reid                                                                                                                                                            |
| 449 |     455.30908 |    295.843921 | Caleb M. Brown                                                                                                                                                        |
| 450 |    1004.73276 |    602.685650 | Ben Liebeskind                                                                                                                                                        |
| 451 |     478.63826 |     65.843992 | Chuanixn Yu                                                                                                                                                           |
| 452 |     561.20801 |    325.680021 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
| 453 |     607.31021 |    399.986450 | Jessica Rick                                                                                                                                                          |
| 454 |     888.13202 |    687.833154 | Pete Buchholz                                                                                                                                                         |
| 455 |     148.35566 |    261.030280 | Scott Hartman                                                                                                                                                         |
| 456 |     895.74609 |     13.041968 | NA                                                                                                                                                                    |
| 457 |     582.85571 |    285.613672 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                       |
| 458 |     340.76857 |    599.262086 | Tasman Dixon                                                                                                                                                          |
| 459 |     748.51002 |    791.679854 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                         |
| 460 |     356.99573 |    745.654295 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 461 |     214.99103 |    643.311295 | Chris huh                                                                                                                                                             |
| 462 |     954.60628 |    125.425262 | Jagged Fang Designs                                                                                                                                                   |
| 463 |     310.37189 |    248.296899 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 464 |     820.55773 |     13.428121 | Gareth Monger                                                                                                                                                         |
| 465 |     793.03743 |    191.131970 | Joanna Wolfe                                                                                                                                                          |
| 466 |     529.29364 |    125.284643 | Smokeybjb                                                                                                                                                             |
| 467 |      78.73760 |    644.997518 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 468 |     626.83536 |    795.297403 | Scott Hartman                                                                                                                                                         |
| 469 |     926.97096 |    344.872383 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                    |
| 470 |      17.38002 |    127.690252 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                      |
| 471 |     564.20615 |     40.793681 | Pete Buchholz                                                                                                                                                         |
| 472 |     158.67469 |    322.741843 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 473 |     986.59544 |    303.957182 | Jagged Fang Designs                                                                                                                                                   |
| 474 |     794.69048 |     38.967558 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
| 475 |     633.36039 |    149.387905 | Dmitry Bogdanov                                                                                                                                                       |
| 476 |     661.80939 |    383.232219 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 477 |      38.09807 |    121.372472 | NASA                                                                                                                                                                  |
| 478 |     733.92447 |    774.887640 | T. Michael Keesey                                                                                                                                                     |
| 479 |     191.43294 |    324.598487 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 480 |     468.01024 |    498.596830 | Christine Axon                                                                                                                                                        |
| 481 |     717.26369 |    193.269167 | T. Michael Keesey                                                                                                                                                     |
| 482 |      83.25995 |    353.765693 | Scott Hartman                                                                                                                                                         |
| 483 |     436.69834 |    686.476308 | Hans Hillewaert                                                                                                                                                       |
| 484 |     193.57157 |    420.564565 | Gareth Monger                                                                                                                                                         |
| 485 |    1008.84478 |    102.247484 | Steven Traver                                                                                                                                                         |
| 486 |     289.27400 |    218.033105 | Neil Kelley                                                                                                                                                           |
| 487 |     443.27577 |    443.532996 | Smokeybjb                                                                                                                                                             |
| 488 |     741.87204 |     72.528014 | T. Michael Keesey                                                                                                                                                     |
| 489 |     217.18317 |     40.763643 | Julio Garza                                                                                                                                                           |
| 490 |     768.99126 |    531.101382 | Jagged Fang Designs                                                                                                                                                   |
| 491 |     609.84635 |      6.243130 | Markus A. Grohme                                                                                                                                                      |
| 492 |     310.64547 |    505.534714 | Margot Michaud                                                                                                                                                        |
| 493 |      34.60063 |    653.407109 | Markus A. Grohme                                                                                                                                                      |
| 494 |     230.76435 |    277.569370 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 495 |     887.88153 |    562.763285 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 496 |     965.13391 |    419.341795 | Gareth Monger                                                                                                                                                         |
| 497 |     292.23097 |    336.770738 | Renata F. Martins                                                                                                                                                     |
| 498 |     508.07020 |    688.599839 | NA                                                                                                                                                                    |
| 499 |     278.80732 |    492.512820 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 500 |     903.02828 |    431.264596 | Abraão Leite                                                                                                                                                          |
| 501 |     387.62083 |    789.313094 | Mathew Wedel                                                                                                                                                          |
| 502 |     855.77704 |    345.144335 | Andy Wilson                                                                                                                                                           |
| 503 |     876.32348 |    717.031448 | Beth Reinke                                                                                                                                                           |
| 504 |      58.73764 |    549.502963 | Chris huh                                                                                                                                                             |
| 505 |      36.29689 |    307.254302 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 506 |     990.09029 |    716.927926 | Amanda Katzer                                                                                                                                                         |
| 507 |     472.20105 |    472.010909 | Sarah Werning                                                                                                                                                         |
| 508 |     661.75692 |    794.443146 | Chris huh                                                                                                                                                             |
| 509 |     961.51356 |    313.175431 | CNZdenek                                                                                                                                                              |
| 510 |     250.23103 |    297.192378 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 511 |     355.12803 |    658.406450 | Milton Tan                                                                                                                                                            |
| 512 |     316.19594 |    178.315573 | Katie S. Collins                                                                                                                                                      |
| 513 |      36.53705 |     52.062781 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 514 |     729.14153 |    610.197923 | Chris huh                                                                                                                                                             |
| 515 |     718.85412 |    406.538247 | Caleb M. Brown                                                                                                                                                        |
| 516 |     970.10895 |    768.120144 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 517 |     416.44008 |    784.416769 | Chris A. Hamilton                                                                                                                                                     |
| 518 |     284.89285 |    106.899100 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 519 |      66.10711 |    577.690301 | Robert Gay                                                                                                                                                            |
| 520 |     987.20660 |    536.741528 | Zimices                                                                                                                                                               |
| 521 |     521.71573 |    106.828177 | Zimices                                                                                                                                                               |
| 522 |      55.67033 |    101.820962 | Scott Hartman                                                                                                                                                         |
| 523 |     917.62602 |    719.595694 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                        |
| 524 |     967.98104 |    401.854877 | Matt Crook                                                                                                                                                            |
| 525 |     582.59610 |    496.801165 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 526 |      61.29418 |    539.650627 | Maija Karala                                                                                                                                                          |
| 527 |     219.54047 |    721.497447 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 528 |     134.32509 |    313.116606 | Smokeybjb                                                                                                                                                             |
| 529 |     894.36711 |    547.043748 | Matt Crook                                                                                                                                                            |
| 530 |     467.22855 |     21.123655 | Dmitry Bogdanov                                                                                                                                                       |
| 531 |     118.32875 |    345.784317 | Jagged Fang Designs                                                                                                                                                   |
| 532 |     185.28621 |    211.348889 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                               |
| 533 |     493.56177 |    369.978446 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 534 |     907.75947 |    403.869851 | Stanton F. Fink, vectorized by Zimices                                                                                                                                |
| 535 |     466.25524 |    311.650002 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                               |
| 536 |      28.30788 |    555.728401 | NA                                                                                                                                                                    |
| 537 |     452.70979 |    655.351144 | Chloé Schmidt                                                                                                                                                         |
| 538 |     624.38974 |    270.039778 | Zimices                                                                                                                                                               |
| 539 |     301.41798 |    141.112702 | Jake Warner                                                                                                                                                           |

    #> Your tweet has been posted!
