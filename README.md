
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

T. Michael Keesey, Steven Traver, Mali’o Kodis, drawing by Manvir Singh,
Carlos Cano-Barbacil, Wayne Decatur, Margot Michaud, Mathieu Basille,
Nobu Tamura (vectorized by T. Michael Keesey), Zimices, Philippe Janvier
(vectorized by T. Michael Keesey), James Neenan, Markus A. Grohme, Matt
Martyniuk, Chris huh, Matt Crook, James R. Spotila and Ray Chatterji,
Jagged Fang Designs, Birgit Lang, Milton Tan, Heinrich Harder
(vectorized by T. Michael Keesey), Ghedoghedo (vectorized by T. Michael
Keesey), Dmitry Bogdanov (vectorized by T. Michael Keesey), Obsidian
Soul (vectorized by T. Michael Keesey), Ferran Sayol, T. Michael Keesey
(after Walker & al.), Jose Carlos Arenas-Monroy, Berivan Temiz, Steven
Haddock • Jellywatch.org, Michelle Site, Tasman Dixon, Shyamal, Gabriela
Palomo-Munoz, Luc Viatour (source photo) and Andreas Plank, Yan Wong,
Thibaut Brunet, Erika Schumacher, Ralf Janssen, Nikola-Michael Prpic &
Wim G. M. Damen (vectorized by T. Michael Keesey), Iain Reid, Philip
Chalmers (vectorized by T. Michael Keesey), Giant Blue Anteater
(vectorized by T. Michael Keesey), Amanda Katzer, Andy Wilson, Gareth
Monger, M Kolmann, Mathew Wedel, Mali’o Kodis, image from Brockhaus and
Efron Encyclopedic Dictionary, Alan Manson (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Jack Mayer Wood, Conty
(vectorized by T. Michael Keesey), Haplochromis (vectorized by T.
Michael Keesey), Lankester Edwin Ray (vectorized by T. Michael Keesey),
Robert Gay, Christoph Schomburg, Ignacio Contreras, Dexter R. Mardis,
Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Jake Warner, Dave Angelini, Kanako Bessho-Uehara, Nobu
Tamura, Griensteidl and T. Michael Keesey, Ramona J Heim, Ellen Edmonson
and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette),
Zimices, based in Mauricio Antón skeletal, Matt Celeskey, Pete Buchholz,
Scott Hartman, Julio Garza, Steven Coombs, Mali’o Kodis, photograph by
Jim Vargo, Timothy Knepp (vectorized by T. Michael Keesey), Caroline
Harding, MAF (vectorized by T. Michael Keesey), Tony Ayling (vectorized
by T. Michael Keesey), Tyler Greenfield, Sergio A. Muñoz-Gómez, Robbie
N. Cada (modified by T. Michael Keesey), Saguaro Pictures (source photo)
and T. Michael Keesey, Aleksey Nagovitsyn (vectorized by T. Michael
Keesey), Adrian Reich, Duane Raver/USFWS, Juan Carlos Jerí, CNZdenek,
FunkMonk, Tim Bertelink (modified by T. Michael Keesey), Johan Lindgren,
Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe, Dmitry Bogdanov,
Tracy A. Heath, Original drawing by Dmitry Bogdanov, vectorized by
Roberto Díaz Sibaja, Jan A. Venter, Herbert H. T. Prins, David A.
Balfour & Rob Slotow (vectorized by T. Michael Keesey), Myriam\_Ramirez,
Cristopher Silva, Gopal Murali, Armelle Ansart (photograph), Maxime
Dahirel (digitisation), Smokeybjb, Katie S. Collins, Chloé Schmidt,
Stacy Spensley (Modified), Keith Murdock (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Michael Scroggie, (after
McCulloch 1908), T. Michael Keesey (photo by J. M. Garg), Tambja
(vectorized by T. Michael Keesey), Terpsichores, Jaime Headden, Sarah
Werning, Mathilde Cordellier, Anthony Caravaggi, Ieuan Jones, Noah
Schlottman, photo by Carol Cummings, Meliponicultor Itaymbere,
SauropodomorphMonarch, Felix Vaux, Rebecca Groom, Skye M, Henry
Lydecker, xgirouxb, Noah Schlottman, photo from Casey Dunn, Jesús Gómez,
vectorized by Zimices, Melissa Broussard, T. Michael Keesey (from a
mount by Allis Markham), Roberto Díaz Sibaja, White Wolf, Alexander
Schmidt-Lebuhn, Agnello Picorelli, Joe Schneid (vectorized by T. Michael
Keesey), Curtis Clark and T. Michael Keesey, Ray Simpson (vectorized by
T. Michael Keesey), Martin R. Smith, Maija Karala, Mark Witton, Marcos
Pérez-Losada, Jens T. Høeg & Keith A. Crandall, Mareike C. Janiak,
Michele M Tobias, Kai R. Caspar, T. Michael Keesey (vectorization) and
Nadiatalent (photography), Mark Miller, Jiekun He, Sean McCann, Becky
Barnes, Margret Flinsch, vectorized by Zimices, Ville-Veikko Sinkkonen,
Collin Gross, Xavier Giroux-Bougard, Frank Denota, T. Tischler, Nobu
Tamura (modified by T. Michael Keesey), Mo Hassan, Chuanixn Yu,
Francesco “Architetto” Rollandin, T. Michael Keesey (photo by Darren
Swim), Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), T. Michael Keesey (from a photo by
Maximilian Paradiz), Gustav Mützel, Martin Kevil, Konsta Happonen,
Sharon Wegner-Larsen, Nobu Tamura, vectorized by Zimices, Mark Hannaford
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Bryan Carstens, Isaure Scavezzoni, Noah Schlottman, photo by
Museum of Geology, University of Tartu, Beth Reinke, Dean Schnabel,
Scott Hartman (vectorized by William Gearty), Mariana Ruiz (vectorized
by T. Michael Keesey), Mali’o Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Marmelad, I.
Sáček, Sr. (vectorized by T. Michael Keesey), Maxwell Lefroy
(vectorized by T. Michael Keesey), Noah Schlottman, photo by Casey Dunn,
Matthew E. Clapham, Jimmy Bernot, Audrey Ely, Michele Tobias, David Orr,
ДиБгд (vectorized by T. Michael Keesey), Joanna Wolfe, Lukasiniho,
Tauana J. Cunha, Timothy Knepp of the U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), Lafage, Kanchi
Nanjo, Trond R. Oskars, Emily Willoughby, Duane Raver (vectorized by T.
Michael Keesey), S.Martini, Christopher Laumer (vectorized by T. Michael
Keesey), Jessica Anne Miller, Theodore W. Pietsch (photography) and T.
Michael Keesey (vectorization), Abraão Leite, Owen Jones (derived from a
CC-BY 2.0 photograph by Paulo B. Chaves), Harold N Eyster, Claus Rebler,
Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Matt Dempsey, Hans Hillewaert (photo) and T. Michael
Keesey (vectorization), Christine Axon, Sarah Alewijnse, E. R. Waite &
H. M. Hale (vectorized by T. Michael Keesey), Sidney Frederic Harmer,
Arthur Everett Shipley (vectorized by Maxime Dahirel), Oscar Sanisidro,
Alex Slavenko, Kamil S. Jaron, Tess Linden, Tomas Willems (vectorized by
T. Michael Keesey), Xavier A. Jenkins, Gabriel Ugueto, Renato de
Carvalho Ferreira, Diana Pomeroy, C. Camilo Julián-Caballero, Chase
Brownstein, Scott Hartman (vectorized by T. Michael Keesey), Alexandre
Vong, Michael P. Taylor, Ricardo Araújo, Darren Naish (vectorized by T.
Michael Keesey), L. Shyamal, Michael Scroggie, from original photograph
by Gary M. Stolz, USFWS (original photograph in public domain)., T.
Michael Keesey (photo by Sean Mack), Felix Vaux and Steven A. Trewick,
Melissa Ingala, Ellen Edmonson (illustration) and Timothy J. Bartley
(silhouette), Dantheman9758 (vectorized by T. Michael Keesey), Riccardo
Percudani, Jakovche, Mali’o Kodis, photograph by Ching
(<http://www.flickr.com/photos/36302473@N03/>), Ghedoghedo, vectorized
by Zimices, Ingo Braasch, Noah Schlottman, John Gould (vectorized by T.
Michael Keesey), Matt Martyniuk (modified by T. Michael Keesey), Noah
Schlottman, photo by Adam G. Clause, Robert Bruce Horsfall, from W.B.
Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”, Jon
Hill (Photo by Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Jay
Matternes (vectorized by T. Michael Keesey), Dori <dori@merr.info>
(source photo) and Nevit Dilmen, Mali’o Kodis, photograph by G. Giribet,
Ben Liebeskind, Robbie N. Cada (vectorized by T. Michael Keesey), Rene
Martin, Mercedes Yrayzoz (vectorized by T. Michael Keesey), Rafael Maia,
Patrick Strutzenberger, Hans Hillewaert, Renato Santos, Karkemish
(vectorized by T. Michael Keesey), Yan Wong from photo by Denes Emoke,
Stanton F. Fink (vectorized by T. Michael Keesey), Lily Hughes,
FJDegrange, Kelly, Bennet McComish, photo by Hans Hillewaert, Mali’o
Kodis, image from Higgins and Kristensen, 1986, Nobu Tamura (vectorized
by A. Verrière), Meyers Konversations-Lexikon 1897 (vectorized: Yan
Wong), Mali’o Kodis, image from the Biodiversity Heritage Library, NASA,
Falconaumanni and T. Michael Keesey, Charles R. Knight, vectorized by
Zimices, Moussa Direct Ltd. (photography) and T. Michael Keesey
(vectorization), Matus Valach, Michael Ströck (vectorized by T. Michael
Keesey), Pedro de Siracusa, Noah Schlottman, photo by David J Patterson,
Eyal Bartov, Michael B. H. (vectorized by T. Michael Keesey), U.S. Fish
and Wildlife Service (illustration) and Timothy J. Bartley (silhouette),
Louis Ranjard, Aadx, André Karwath (vectorized by T. Michael Keesey),
Joshua Fowler, Eduard Solà (vectorized by T. Michael Keesey), A. R.
McCulloch (vectorized by T. Michael Keesey), Gordon E. Robertson, Jerry
Oldenettel (vectorized by T. Michael Keesey), J. J. Harrison (photo) &
T. Michael Keesey, \[unknown\], DW Bapst, modified from Ishitani et
al. 2016, Scott Hartman, modified by T. Michael Keesey, T. Michael
Keesey (vectorization) and HuttyMcphoo (photography), Arthur S. Brum,
Maxime Dahirel

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                         |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    538.248957 |    653.141215 | T. Michael Keesey                                                                                                                                              |
|   2 |    289.055203 |    426.432752 | Steven Traver                                                                                                                                                  |
|   3 |    507.516475 |    737.462751 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                          |
|   4 |    654.215312 |    202.931691 | Carlos Cano-Barbacil                                                                                                                                           |
|   5 |    117.873484 |    424.732719 | Wayne Decatur                                                                                                                                                  |
|   6 |    919.185659 |    632.894308 | Margot Michaud                                                                                                                                                 |
|   7 |    499.744888 |    566.878751 | Margot Michaud                                                                                                                                                 |
|   8 |    289.720674 |    278.896769 | Wayne Decatur                                                                                                                                                  |
|   9 |    744.220133 |    442.809903 | Margot Michaud                                                                                                                                                 |
|  10 |    411.896410 |     42.246847 | Mathieu Basille                                                                                                                                                |
|  11 |    893.278699 |    327.290335 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  12 |    595.532653 |    754.314657 | T. Michael Keesey                                                                                                                                              |
|  13 |    875.017475 |    262.973538 | Zimices                                                                                                                                                        |
|  14 |    485.539419 |    372.270576 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                             |
|  15 |    723.810677 |    314.850593 | James Neenan                                                                                                                                                   |
|  16 |    205.204968 |    723.790225 | Markus A. Grohme                                                                                                                                               |
|  17 |    404.944000 |    563.233803 | Matt Martyniuk                                                                                                                                                 |
|  18 |    134.855631 |    671.587850 | Chris huh                                                                                                                                                      |
|  19 |    878.732613 |    165.344860 | Matt Crook                                                                                                                                                     |
|  20 |    685.831194 |    590.089429 | James R. Spotila and Ray Chatterji                                                                                                                             |
|  21 |    371.667179 |    738.900289 | Jagged Fang Designs                                                                                                                                            |
|  22 |     22.030141 |    500.722651 | T. Michael Keesey                                                                                                                                              |
|  23 |    430.666205 |    167.694220 | Birgit Lang                                                                                                                                                    |
|  24 |     65.970577 |    601.199493 | Milton Tan                                                                                                                                                     |
|  25 |    547.380183 |    134.784945 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                              |
|  26 |    225.508650 |    547.477866 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
|  27 |    702.011084 |    658.858002 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
|  28 |    519.197928 |    217.972602 | Chris huh                                                                                                                                                      |
|  29 |    809.782385 |    120.193970 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
|  30 |    177.306681 |    103.968245 | Ferran Sayol                                                                                                                                                   |
|  31 |    501.488348 |    462.646536 | Markus A. Grohme                                                                                                                                               |
|  32 |    664.534463 |    373.566636 | T. Michael Keesey (after Walker & al.)                                                                                                                         |
|  33 |    923.470476 |    435.244480 | Jose Carlos Arenas-Monroy                                                                                                                                      |
|  34 |    753.632396 |    532.190266 | Zimices                                                                                                                                                        |
|  35 |    580.626255 |    500.669268 | Zimices                                                                                                                                                        |
|  36 |    130.671368 |     36.237828 | Berivan Temiz                                                                                                                                                  |
|  37 |    534.848043 |    275.800792 | Steven Traver                                                                                                                                                  |
|  38 |    104.150548 |    175.612985 | Steven Haddock • Jellywatch.org                                                                                                                                |
|  39 |    101.334915 |    305.365940 | Michelle Site                                                                                                                                                  |
|  40 |    112.928995 |    741.681658 | Tasman Dixon                                                                                                                                                   |
|  41 |    894.097349 |     54.507445 | Shyamal                                                                                                                                                        |
|  42 |    321.423321 |     80.020299 | Gabriela Palomo-Munoz                                                                                                                                          |
|  43 |    788.457693 |    595.827472 | Ferran Sayol                                                                                                                                                   |
|  44 |    543.888848 |    391.015865 | Luc Viatour (source photo) and Andreas Plank                                                                                                                   |
|  45 |    900.502085 |    754.025795 | Yan Wong                                                                                                                                                       |
|  46 |    688.174204 |    261.457600 | Thibaut Brunet                                                                                                                                                 |
|  47 |    739.449211 |     47.397925 | Zimices                                                                                                                                                        |
|  48 |    312.233351 |    694.069501 | Erika Schumacher                                                                                                                                               |
|  49 |    547.647537 |     40.364073 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                         |
|  50 |    616.227220 |    448.599563 | Iain Reid                                                                                                                                                      |
|  51 |    743.223526 |    740.163132 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                              |
|  52 |    926.095757 |    515.899558 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                          |
|  53 |    438.279419 |    300.355230 | Amanda Katzer                                                                                                                                                  |
|  54 |    923.043293 |    353.428962 | Markus A. Grohme                                                                                                                                               |
|  55 |    302.999630 |    165.174995 | Zimices                                                                                                                                                        |
|  56 |    402.429415 |    480.612706 | Andy Wilson                                                                                                                                                    |
|  57 |    978.967560 |    645.410732 | Gareth Monger                                                                                                                                                  |
|  58 |    198.394831 |    471.935903 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
|  59 |    572.334380 |    720.725294 | Gareth Monger                                                                                                                                                  |
|  60 |     81.841011 |    369.844533 | M Kolmann                                                                                                                                                      |
|  61 |    951.077543 |    204.355628 | Margot Michaud                                                                                                                                                 |
|  62 |    687.562146 |    117.326074 | Margot Michaud                                                                                                                                                 |
|  63 |    189.981353 |    180.266658 | Erika Schumacher                                                                                                                                               |
|  64 |    191.545359 |    617.933815 | Mathew Wedel                                                                                                                                                   |
|  65 |    831.100426 |    443.355700 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                           |
|  66 |    797.815919 |    181.582718 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
|  67 |    182.501653 |    258.246732 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
|  68 |    445.232724 |    518.235217 | Jack Mayer Wood                                                                                                                                                |
|  69 |    431.265822 |    688.739833 | Conty (vectorized by T. Michael Keesey)                                                                                                                        |
|  70 |    985.649227 |    276.780443 | Ferran Sayol                                                                                                                                                   |
|  71 |    247.479736 |    368.739112 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                 |
|  72 |    337.740297 |    773.625826 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                         |
|  73 |    605.162227 |    781.263213 | Jagged Fang Designs                                                                                                                                            |
|  74 |    613.624860 |    353.896991 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                          |
|  75 |    751.323566 |    358.387635 | Carlos Cano-Barbacil                                                                                                                                           |
|  76 |    336.939699 |    624.181299 | Robert Gay                                                                                                                                                     |
|  77 |    527.254668 |    601.833051 | Christoph Schomburg                                                                                                                                            |
|  78 |    736.148332 |    285.725803 | Ignacio Contreras                                                                                                                                              |
|  79 |     78.233987 |    540.544341 | Mathieu Basille                                                                                                                                                |
|  80 |    313.749255 |    203.497300 | Gareth Monger                                                                                                                                                  |
|  81 |     69.177343 |    234.965383 | Dexter R. Mardis                                                                                                                                               |
|  82 |    376.759007 |    354.852342 | Markus A. Grohme                                                                                                                                               |
|  83 |    434.764858 |    224.970721 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey   |
|  84 |     49.866116 |    123.852554 | Jake Warner                                                                                                                                                    |
|  85 |     43.070898 |    378.784481 | Dave Angelini                                                                                                                                                  |
|  86 |    956.117846 |    565.497257 | Gareth Monger                                                                                                                                                  |
|  87 |    702.714273 |    683.613372 | Kanako Bessho-Uehara                                                                                                                                           |
|  88 |    647.073356 |    343.353061 | Margot Michaud                                                                                                                                                 |
|  89 |    976.568990 |    703.561338 | Jagged Fang Designs                                                                                                                                            |
|  90 |   1006.019526 |    467.700903 | Nobu Tamura                                                                                                                                                    |
|  91 |    455.074569 |    765.283634 | Griensteidl and T. Michael Keesey                                                                                                                              |
|  92 |    670.140130 |    709.547075 | Matt Crook                                                                                                                                                     |
|  93 |    289.807957 |    480.113309 | Gabriela Palomo-Munoz                                                                                                                                          |
|  94 |    608.310980 |    585.527653 | Ramona J Heim                                                                                                                                                  |
|  95 |    862.825774 |    481.618444 | Zimices                                                                                                                                                        |
|  96 |    346.654614 |    598.532592 | Jack Mayer Wood                                                                                                                                                |
|  97 |    665.252168 |    753.889805 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                              |
|  98 |    627.644112 |    558.465844 | NA                                                                                                                                                             |
|  99 |    776.739510 |    256.654700 | Zimices, based in Mauricio Antón skeletal                                                                                                                      |
| 100 |    307.427520 |    503.129137 | Yan Wong                                                                                                                                                       |
| 101 |    985.650483 |     58.196863 | Matt Celeskey                                                                                                                                                  |
| 102 |    780.656010 |     15.386746 | Pete Buchholz                                                                                                                                                  |
| 103 |    580.777455 |    543.439671 | Gabriela Palomo-Munoz                                                                                                                                          |
| 104 |    647.303075 |    771.190776 | Scott Hartman                                                                                                                                                  |
| 105 |    850.784603 |    541.038205 | Julio Garza                                                                                                                                                    |
| 106 |    400.235284 |    422.465459 | Jagged Fang Designs                                                                                                                                            |
| 107 |    734.320111 |    173.716634 | Steven Coombs                                                                                                                                                  |
| 108 |    955.593339 |    627.494510 | Matt Crook                                                                                                                                                     |
| 109 |    383.888509 |     88.239627 | Steven Traver                                                                                                                                                  |
| 110 |     57.304439 |     14.478369 | Mali’o Kodis, photograph by Jim Vargo                                                                                                                          |
| 111 |    576.129977 |    204.593627 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                |
| 112 |    413.072846 |    108.977020 | Scott Hartman                                                                                                                                                  |
| 113 |     29.344428 |     68.972364 | Matt Crook                                                                                                                                                     |
| 114 |    977.604612 |    549.736294 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                        |
| 115 |    792.076299 |    759.022721 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                  |
| 116 |    614.818193 |    682.923376 | Tyler Greenfield                                                                                                                                               |
| 117 |    427.521900 |    442.990250 | Sergio A. Muñoz-Gómez                                                                                                                                          |
| 118 |    310.143444 |    594.843588 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                 |
| 119 |    199.640430 |    239.940659 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                          |
| 120 |    171.560799 |    201.135200 | Zimices                                                                                                                                                        |
| 121 |    825.843332 |    514.804273 | Aleksey Nagovitsyn (vectorized by T. Michael Keesey)                                                                                                           |
| 122 |    814.029838 |    289.696294 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 123 |    263.096462 |    182.500824 | Adrian Reich                                                                                                                                                   |
| 124 |    645.502862 |    354.559957 | Zimices                                                                                                                                                        |
| 125 |    455.513314 |    217.745035 | Margot Michaud                                                                                                                                                 |
| 126 |     15.078329 |    398.787127 | Matt Crook                                                                                                                                                     |
| 127 |    681.290330 |    638.063294 | Duane Raver/USFWS                                                                                                                                              |
| 128 |    757.733331 |    129.909713 | Andy Wilson                                                                                                                                                    |
| 129 |    438.380848 |    271.100807 | Juan Carlos Jerí                                                                                                                                               |
| 130 |    997.067764 |    148.429831 | CNZdenek                                                                                                                                                       |
| 131 |    926.977939 |    593.773582 | FunkMonk                                                                                                                                                       |
| 132 |    378.827919 |    509.164915 | Shyamal                                                                                                                                                        |
| 133 |    762.600638 |    338.356748 | Carlos Cano-Barbacil                                                                                                                                           |
| 134 |   1006.225756 |     95.707505 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                  |
| 135 |    984.200463 |    722.044572 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                           |
| 136 |    575.573527 |    343.627108 | Scott Hartman                                                                                                                                                  |
| 137 |    215.209245 |    419.030422 | Chris huh                                                                                                                                                      |
| 138 |     56.883219 |     50.582660 | Shyamal                                                                                                                                                        |
| 139 |    966.551020 |    375.194640 | Matt Crook                                                                                                                                                     |
| 140 |    171.295291 |    380.119145 | Matt Crook                                                                                                                                                     |
| 141 |   1009.785841 |    745.835335 | Dmitry Bogdanov                                                                                                                                                |
| 142 |     81.232574 |    473.237889 | Margot Michaud                                                                                                                                                 |
| 143 |    357.329437 |    581.709304 | Tracy A. Heath                                                                                                                                                 |
| 144 |    596.360337 |    689.391239 | Scott Hartman                                                                                                                                                  |
| 145 |    387.555989 |    336.220751 | Jagged Fang Designs                                                                                                                                            |
| 146 |    220.070856 |    699.724596 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                         |
| 147 |    149.601841 |    223.083492 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 148 |    816.684282 |    760.724337 | Gabriela Palomo-Munoz                                                                                                                                          |
| 149 |    588.020157 |    694.952460 | Myriam\_Ramirez                                                                                                                                                |
| 150 |    234.669795 |    425.530934 | Michelle Site                                                                                                                                                  |
| 151 |    934.822311 |    537.015443 | Cristopher Silva                                                                                                                                               |
| 152 |   1015.252312 |    602.298987 | Zimices                                                                                                                                                        |
| 153 |    760.103548 |    163.246689 | Gopal Murali                                                                                                                                                   |
| 154 |    594.133461 |     85.765060 | Gabriela Palomo-Munoz                                                                                                                                          |
| 155 |     44.046484 |    334.155507 | Gareth Monger                                                                                                                                                  |
| 156 |    747.020575 |    573.858500 | Matt Crook                                                                                                                                                     |
| 157 |    449.723369 |    641.498085 | Mathew Wedel                                                                                                                                                   |
| 158 |    978.495047 |    496.683029 | Armelle Ansart (photograph), Maxime Dahirel (digitisation)                                                                                                     |
| 159 |    580.152870 |      6.954033 | Margot Michaud                                                                                                                                                 |
| 160 |    759.240495 |    144.454605 | Smokeybjb                                                                                                                                                      |
| 161 |     70.265603 |    770.335578 | Steven Traver                                                                                                                                                  |
| 162 |     73.661352 |    392.262118 | Katie S. Collins                                                                                                                                               |
| 163 |    959.263303 |    170.298261 | Gareth Monger                                                                                                                                                  |
| 164 |    758.972810 |    321.859263 | Scott Hartman                                                                                                                                                  |
| 165 |    516.809127 |     87.795120 | Chloé Schmidt                                                                                                                                                  |
| 166 |    800.931290 |    692.496291 | Dmitry Bogdanov                                                                                                                                                |
| 167 |    854.654733 |    110.261323 | Stacy Spensley (Modified)                                                                                                                                      |
| 168 |    724.662461 |    570.518350 | Gabriela Palomo-Munoz                                                                                                                                          |
| 169 |    712.452251 |    149.357633 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 170 |    536.512411 |    189.866569 | NA                                                                                                                                                             |
| 171 |    214.304880 |    469.514797 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey  |
| 172 |    487.540175 |    136.168176 | Michael Scroggie                                                                                                                                               |
| 173 |    633.440052 |    734.817951 | (after McCulloch 1908)                                                                                                                                         |
| 174 |    464.929210 |    207.475145 | Scott Hartman                                                                                                                                                  |
| 175 |     13.227986 |    634.734113 | Margot Michaud                                                                                                                                                 |
| 176 |    131.531994 |    705.680026 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                        |
| 177 |     97.130996 |    663.465759 | Tasman Dixon                                                                                                                                                   |
| 178 |   1006.642868 |    782.237783 | Tasman Dixon                                                                                                                                                   |
| 179 |    738.272632 |    128.840343 | Matt Crook                                                                                                                                                     |
| 180 |     13.827212 |      8.686184 | Zimices                                                                                                                                                        |
| 181 |     38.431507 |    171.047943 | Tambja (vectorized by T. Michael Keesey)                                                                                                                       |
| 182 |    453.803110 |    131.023971 | Zimices                                                                                                                                                        |
| 183 |    253.218504 |    620.970631 | Terpsichores                                                                                                                                                   |
| 184 |    413.859155 |    239.292855 | Jaime Headden                                                                                                                                                  |
| 185 |     18.641126 |    191.221319 | Sarah Werning                                                                                                                                                  |
| 186 |    392.843999 |     12.335609 | Matt Crook                                                                                                                                                     |
| 187 |    826.648738 |     96.554108 | Andy Wilson                                                                                                                                                    |
| 188 |     21.849175 |    158.900380 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 189 |    628.440330 |    287.027026 | Carlos Cano-Barbacil                                                                                                                                           |
| 190 |     44.634642 |    450.167164 | Margot Michaud                                                                                                                                                 |
| 191 |    686.529204 |     36.386588 | Mathilde Cordellier                                                                                                                                            |
| 192 |    232.795815 |    687.058341 | Anthony Caravaggi                                                                                                                                              |
| 193 |    928.560594 |    171.313150 | NA                                                                                                                                                             |
| 194 |   1015.431092 |    511.758781 | Ferran Sayol                                                                                                                                                   |
| 195 |    357.445920 |     81.312570 | Scott Hartman                                                                                                                                                  |
| 196 |    857.576064 |    527.840603 | Margot Michaud                                                                                                                                                 |
| 197 |    803.234922 |    223.830234 | Zimices                                                                                                                                                        |
| 198 |    274.250034 |    175.926689 | Ieuan Jones                                                                                                                                                    |
| 199 |     55.675727 |    470.829272 | Steven Traver                                                                                                                                                  |
| 200 |    146.974480 |    501.325770 | NA                                                                                                                                                             |
| 201 |    432.512624 |    660.454932 | Noah Schlottman, photo by Carol Cummings                                                                                                                       |
| 202 |    363.692302 |     21.096851 | Chris huh                                                                                                                                                      |
| 203 |    543.029405 |    316.777998 | Meliponicultor Itaymbere                                                                                                                                       |
| 204 |    326.677939 |    470.297918 | Pete Buchholz                                                                                                                                                  |
| 205 |    450.951287 |    708.782893 | Zimices                                                                                                                                                        |
| 206 |    368.470135 |    167.394868 | Erika Schumacher                                                                                                                                               |
| 207 |    732.200966 |    682.137083 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 208 |    203.470871 |     37.271942 | SauropodomorphMonarch                                                                                                                                          |
| 209 |    643.235846 |    381.284376 | Margot Michaud                                                                                                                                                 |
| 210 |     99.680901 |    784.368415 | Ferran Sayol                                                                                                                                                   |
| 211 |    586.651560 |    333.925880 | Felix Vaux                                                                                                                                                     |
| 212 |    561.354226 |    161.591474 | Rebecca Groom                                                                                                                                                  |
| 213 |    708.974055 |    381.701052 | Skye M                                                                                                                                                         |
| 214 |    448.500163 |    342.062306 | Henry Lydecker                                                                                                                                                 |
| 215 |    745.020991 |    218.624194 | xgirouxb                                                                                                                                                       |
| 216 |    148.653049 |    143.124630 | FunkMonk                                                                                                                                                       |
| 217 |    432.319499 |    623.586566 | Zimices                                                                                                                                                        |
| 218 |   1005.709097 |    492.722758 | Gareth Monger                                                                                                                                                  |
| 219 |    145.915524 |    368.676809 | Noah Schlottman, photo from Casey Dunn                                                                                                                         |
| 220 |    732.147284 |    381.957510 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 221 |    506.385159 |    533.698253 | Gareth Monger                                                                                                                                                  |
| 222 |    624.883938 |    167.211109 | Jesús Gómez, vectorized by Zimices                                                                                                                             |
| 223 |    569.327700 |    613.671041 | Jagged Fang Designs                                                                                                                                            |
| 224 |    664.338288 |    631.333966 | Melissa Broussard                                                                                                                                              |
| 225 |    500.283738 |    319.267641 | Jagged Fang Designs                                                                                                                                            |
| 226 |    406.011418 |    539.900410 | Steven Coombs                                                                                                                                                  |
| 227 |    869.059324 |    156.838403 | Felix Vaux                                                                                                                                                     |
| 228 |    440.189315 |     59.467213 | NA                                                                                                                                                             |
| 229 |    629.626573 |    520.860966 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                              |
| 230 |    177.715883 |    348.709478 | Roberto Díaz Sibaja                                                                                                                                            |
| 231 |    814.549123 |    339.796378 | Gabriela Palomo-Munoz                                                                                                                                          |
| 232 |    356.953173 |    132.495114 | White Wolf                                                                                                                                                     |
| 233 |    366.688039 |    385.482272 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 234 |    473.355453 |    486.525089 | Agnello Picorelli                                                                                                                                              |
| 235 |    841.689400 |    358.725033 | Andy Wilson                                                                                                                                                    |
| 236 |     33.377843 |    644.151829 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                  |
| 237 |    656.714068 |    396.382872 | Curtis Clark and T. Michael Keesey                                                                                                                             |
| 238 |    920.163667 |     89.315271 | Matt Crook                                                                                                                                                     |
| 239 |    225.767212 |    616.732398 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                  |
| 240 |    880.113483 |    468.948476 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 241 |    717.493888 |    236.197639 | Iain Reid                                                                                                                                                      |
| 242 |    922.676730 |    524.494351 | Shyamal                                                                                                                                                        |
| 243 |    351.902277 |    416.984556 | Martin R. Smith                                                                                                                                                |
| 244 |   1007.391291 |    441.089774 | Christoph Schomburg                                                                                                                                            |
| 245 |    226.075530 |     29.115954 | Margot Michaud                                                                                                                                                 |
| 246 |    156.319533 |    256.630754 | Steven Traver                                                                                                                                                  |
| 247 |    452.389020 |    267.471848 | Maija Karala                                                                                                                                                   |
| 248 |    578.192432 |    315.361847 | Margot Michaud                                                                                                                                                 |
| 249 |     37.069510 |     98.174241 | Mark Witton                                                                                                                                                    |
| 250 |    356.410093 |    508.135527 | Iain Reid                                                                                                                                                      |
| 251 |    611.629907 |    266.933749 | Maija Karala                                                                                                                                                   |
| 252 |    307.261963 |     59.589655 | Zimices                                                                                                                                                        |
| 253 |    324.687749 |    751.062425 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                          |
| 254 |    544.954102 |    369.869714 | Ferran Sayol                                                                                                                                                   |
| 255 |    696.536658 |    167.776407 | Birgit Lang                                                                                                                                                    |
| 256 |     12.912953 |     54.340964 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 257 |    796.577181 |    507.662793 | Mareike C. Janiak                                                                                                                                              |
| 258 |    246.023760 |    457.214954 | Jagged Fang Designs                                                                                                                                            |
| 259 |    647.752669 |    486.710023 | Ferran Sayol                                                                                                                                                   |
| 260 |    458.613087 |    731.474475 | Iain Reid                                                                                                                                                      |
| 261 |    335.891168 |     38.253084 | Michele M Tobias                                                                                                                                               |
| 262 |    657.986871 |    526.064985 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 263 |    566.690010 |    318.670131 | Gabriela Palomo-Munoz                                                                                                                                          |
| 264 |    431.944490 |     88.566909 | Agnello Picorelli                                                                                                                                              |
| 265 |    512.888802 |    239.309003 | Margot Michaud                                                                                                                                                 |
| 266 |    358.366290 |    640.574520 | Iain Reid                                                                                                                                                      |
| 267 |    656.677978 |    536.190558 | Milton Tan                                                                                                                                                     |
| 268 |    356.005502 |    515.825533 | T. Michael Keesey                                                                                                                                              |
| 269 |    348.796081 |    325.773896 | Kai R. Caspar                                                                                                                                                  |
| 270 |    667.518378 |    487.688497 | Matt Crook                                                                                                                                                     |
| 271 |    393.714701 |    640.965529 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                |
| 272 |    855.564169 |    354.913037 | Mark Miller                                                                                                                                                    |
| 273 |    353.017512 |    386.390950 | Scott Hartman                                                                                                                                                  |
| 274 |    587.063676 |    179.391019 | T. Michael Keesey                                                                                                                                              |
| 275 |    418.543635 |    438.409511 | Gopal Murali                                                                                                                                                   |
| 276 |     37.874675 |    657.782309 | Margot Michaud                                                                                                                                                 |
| 277 |    195.345246 |    344.684897 | Jiekun He                                                                                                                                                      |
| 278 |    263.687689 |     30.248984 | Matt Crook                                                                                                                                                     |
| 279 |    481.551881 |    540.077730 | Matt Crook                                                                                                                                                     |
| 280 |     38.794213 |    779.670739 | Dmitry Bogdanov                                                                                                                                                |
| 281 |    797.753143 |    593.815224 | Scott Hartman                                                                                                                                                  |
| 282 |    651.391119 |    708.852457 | Matt Crook                                                                                                                                                     |
| 283 |    492.309251 |    591.799744 | Anthony Caravaggi                                                                                                                                              |
| 284 |     70.749193 |    117.781763 | Sean McCann                                                                                                                                                    |
| 285 |    920.128764 |    152.650160 | Becky Barnes                                                                                                                                                   |
| 286 |    739.039144 |    687.012042 | Margret Flinsch, vectorized by Zimices                                                                                                                         |
| 287 |    738.370219 |    231.882943 | Ville-Veikko Sinkkonen                                                                                                                                         |
| 288 |    888.548456 |    151.052938 | Shyamal                                                                                                                                                        |
| 289 |    494.235799 |     70.055197 | Ferran Sayol                                                                                                                                                   |
| 290 |    368.670502 |    609.901648 | Gopal Murali                                                                                                                                                   |
| 291 |    315.268912 |    124.999702 | Collin Gross                                                                                                                                                   |
| 292 |    973.004154 |    357.505738 | Xavier Giroux-Bougard                                                                                                                                          |
| 293 |    155.535190 |    148.643499 | Matt Crook                                                                                                                                                     |
| 294 |    102.455630 |    695.577058 | Scott Hartman                                                                                                                                                  |
| 295 |    560.463644 |     93.370264 | Frank Denota                                                                                                                                                   |
| 296 |     16.646349 |    747.833391 | T. Tischler                                                                                                                                                    |
| 297 |    645.060409 |    633.761127 | Zimices                                                                                                                                                        |
| 298 |    823.092282 |    637.086266 | T. Michael Keesey                                                                                                                                              |
| 299 |    154.970776 |    631.112024 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                         |
| 300 |    736.455082 |      9.462671 | Markus A. Grohme                                                                                                                                               |
| 301 |    400.265092 |    742.686378 | Matt Crook                                                                                                                                                     |
| 302 |    860.614948 |    589.791215 | Nobu Tamura                                                                                                                                                    |
| 303 |    940.685641 |    646.160990 | Margot Michaud                                                                                                                                                 |
| 304 |     81.821363 |    643.118143 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 305 |    944.392331 |    547.234698 | Gareth Monger                                                                                                                                                  |
| 306 |    690.886776 |    554.348823 | Chris huh                                                                                                                                                      |
| 307 |     69.104269 |    522.541382 | Steven Traver                                                                                                                                                  |
| 308 |     27.178739 |    252.502963 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                    |
| 309 |    156.512958 |    278.962215 | Margot Michaud                                                                                                                                                 |
| 310 |   1002.190657 |    124.262334 | Mo Hassan                                                                                                                                                      |
| 311 |    370.248132 |    317.412137 | Katie S. Collins                                                                                                                                               |
| 312 |    112.391197 |    127.487536 | Steven Traver                                                                                                                                                  |
| 313 |    314.418808 |    111.756235 | Chuanixn Yu                                                                                                                                                    |
| 314 |    144.826906 |    786.658101 | Iain Reid                                                                                                                                                      |
| 315 |    154.830205 |    458.997699 | Ferran Sayol                                                                                                                                                   |
| 316 |    707.504193 |    626.998409 | NA                                                                                                                                                             |
| 317 |    246.499886 |    779.195743 | Gabriela Palomo-Munoz                                                                                                                                          |
| 318 |     40.053605 |    749.657938 | Tracy A. Heath                                                                                                                                                 |
| 319 |    422.418918 |    150.096546 | Francesco “Architetto” Rollandin                                                                                                                               |
| 320 |    846.767098 |    783.699808 | Andy Wilson                                                                                                                                                    |
| 321 |    212.426717 |    392.617185 | Steven Traver                                                                                                                                                  |
| 322 |    641.369857 |    252.634080 | Chris huh                                                                                                                                                      |
| 323 |     45.711218 |    145.303726 | Noah Schlottman, photo from Casey Dunn                                                                                                                         |
| 324 |    667.154761 |    686.716338 | NA                                                                                                                                                             |
| 325 |     17.749118 |     21.636509 | T. Michael Keesey                                                                                                                                              |
| 326 |    803.096833 |    465.216493 | Juan Carlos Jerí                                                                                                                                               |
| 327 |    650.815669 |    740.736279 | T. Michael Keesey (photo by Darren Swim)                                                                                                                       |
| 328 |    970.806145 |    790.446087 | White Wolf                                                                                                                                                     |
| 329 |    961.902037 |    294.972359 | Collin Gross                                                                                                                                                   |
| 330 |   1005.005573 |    405.071818 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                   |
| 331 |    398.437989 |    378.838951 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                         |
| 332 |    202.937417 |     44.737456 | Gustav Mützel                                                                                                                                                  |
| 333 |    654.657002 |     20.494318 | Chris huh                                                                                                                                                      |
| 334 |    185.393442 |    381.890283 | Xavier Giroux-Bougard                                                                                                                                          |
| 335 |    751.523636 |    327.247982 | Martin Kevil                                                                                                                                                   |
| 336 |    240.756657 |    350.965611 | Konsta Happonen                                                                                                                                                |
| 337 |    558.749004 |    696.770242 | Gabriela Palomo-Munoz                                                                                                                                          |
| 338 |    167.769106 |    242.249114 | Sarah Werning                                                                                                                                                  |
| 339 |   1002.323300 |    361.766201 | Sharon Wegner-Larsen                                                                                                                                           |
| 340 |    983.656475 |    576.311506 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                              |
| 341 |    934.545701 |    150.334061 | Matt Crook                                                                                                                                                     |
| 342 |    223.104321 |    785.296930 | Matt Crook                                                                                                                                                     |
| 343 |    468.099809 |    246.691216 | Gareth Monger                                                                                                                                                  |
| 344 |    398.429573 |    237.532507 | Jaime Headden                                                                                                                                                  |
| 345 |    516.710694 |    741.231561 | Gabriela Palomo-Munoz                                                                                                                                          |
| 346 |    987.208929 |    786.068834 | Katie S. Collins                                                                                                                                               |
| 347 |    245.521386 |    464.804469 | Tracy A. Heath                                                                                                                                                 |
| 348 |    505.149463 |     82.656370 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 349 |    141.227119 |    641.729836 | Margot Michaud                                                                                                                                                 |
| 350 |    260.416871 |    105.367955 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 351 |     44.202379 |    703.594035 | Ignacio Contreras                                                                                                                                              |
| 352 |    851.363223 |    685.046408 | NA                                                                                                                                                             |
| 353 |    175.503530 |    775.499507 | Gareth Monger                                                                                                                                                  |
| 354 |    588.354689 |    772.595863 | Carlos Cano-Barbacil                                                                                                                                           |
| 355 |    422.767781 |    275.781591 | Matt Crook                                                                                                                                                     |
| 356 |     49.499789 |    666.790710 | Gabriela Palomo-Munoz                                                                                                                                          |
| 357 |    888.111900 |    544.039173 | Zimices                                                                                                                                                        |
| 358 |    663.116356 |    785.608667 | Andy Wilson                                                                                                                                                    |
| 359 |    477.643698 |    440.692007 | Bryan Carstens                                                                                                                                                 |
| 360 |    900.390192 |      8.437170 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                |
| 361 |    401.839642 |    328.419450 | Isaure Scavezzoni                                                                                                                                              |
| 362 |    641.091390 |     12.098454 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 363 |    668.141451 |      9.143790 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                               |
| 364 |    336.055777 |    703.912808 | Beth Reinke                                                                                                                                                    |
| 365 |     47.457032 |    774.674469 | NA                                                                                                                                                             |
| 366 |    106.956996 |    112.333974 | Dean Schnabel                                                                                                                                                  |
| 367 |    798.885766 |    720.279586 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                    |
| 368 |    533.576557 |    612.438172 | Scott Hartman (vectorized by William Gearty)                                                                                                                   |
| 369 |    802.199547 |     30.953657 | T. Michael Keesey                                                                                                                                              |
| 370 |    943.582855 |    606.330116 | Zimices                                                                                                                                                        |
| 371 |    750.413258 |    199.697050 | Katie S. Collins                                                                                                                                               |
| 372 |     12.332490 |    328.912383 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                 |
| 373 |    454.679223 |    328.519037 | NA                                                                                                                                                             |
| 374 |    338.118859 |    652.050210 | T. Michael Keesey                                                                                                                                              |
| 375 |    808.316047 |     68.079757 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                          |
| 376 |    422.683168 |    791.067407 | Tasman Dixon                                                                                                                                                   |
| 377 |    978.930800 |    143.817139 | Marmelad                                                                                                                                                       |
| 378 |     49.174831 |    414.430191 | T. Michael Keesey                                                                                                                                              |
| 379 |    377.554446 |    184.895192 | I. Sáček, Sr. (vectorized by T. Michael Keesey)                                                                                                                |
| 380 |    614.158450 |    124.702329 | Shyamal                                                                                                                                                        |
| 381 |      8.008116 |     41.597116 | Rebecca Groom                                                                                                                                                  |
| 382 |     46.405750 |    789.999414 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                               |
| 383 |    444.978821 |    143.763594 | Noah Schlottman, photo by Casey Dunn                                                                                                                           |
| 384 |    481.708804 |    330.655022 | T. Michael Keesey                                                                                                                                              |
| 385 |    810.928371 |    280.798150 | NA                                                                                                                                                             |
| 386 |    279.909346 |     21.603935 | Zimices                                                                                                                                                        |
| 387 |     30.759068 |     16.272255 | Matthew E. Clapham                                                                                                                                             |
| 388 |    653.659021 |    288.293202 | Jimmy Bernot                                                                                                                                                   |
| 389 |    438.641668 |    425.545079 | Steven Traver                                                                                                                                                  |
| 390 |    878.751328 |    142.584574 | Audrey Ely                                                                                                                                                     |
| 391 |    514.129990 |    431.012286 | Matt Crook                                                                                                                                                     |
| 392 |    331.930580 |    372.677084 | Felix Vaux                                                                                                                                                     |
| 393 |    935.997218 |      4.525204 | Margot Michaud                                                                                                                                                 |
| 394 |    448.708216 |    195.261734 | Julio Garza                                                                                                                                                    |
| 395 |    180.291552 |    760.320372 | Yan Wong                                                                                                                                                       |
| 396 |    453.195576 |    430.587702 | Michele Tobias                                                                                                                                                 |
| 397 |    775.666893 |    674.370619 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 398 |    654.144039 |    301.976900 | David Orr                                                                                                                                                      |
| 399 |    964.140868 |    303.250331 | Collin Gross                                                                                                                                                   |
| 400 |    151.801945 |    325.475635 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                        |
| 401 |    652.893097 |     43.610074 | Rebecca Groom                                                                                                                                                  |
| 402 |    417.759484 |    648.906016 | Tasman Dixon                                                                                                                                                   |
| 403 |    638.023249 |    679.809621 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                        |
| 404 |    776.515216 |    320.870636 | Birgit Lang                                                                                                                                                    |
| 405 |    258.912752 |    636.165795 | Beth Reinke                                                                                                                                                    |
| 406 |    638.680736 |    315.506052 | Maija Karala                                                                                                                                                   |
| 407 |    256.085525 |    427.224862 | Dean Schnabel                                                                                                                                                  |
| 408 |    633.849350 |    604.832019 | Joanna Wolfe                                                                                                                                                   |
| 409 |    386.774592 |    287.376456 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 410 |    733.895031 |     82.264333 | Jagged Fang Designs                                                                                                                                            |
| 411 |    408.191244 |    340.171064 | Lukasiniho                                                                                                                                                     |
| 412 |    881.978685 |    579.402790 | Tauana J. Cunha                                                                                                                                                |
| 413 |    995.915461 |    355.930812 | NA                                                                                                                                                             |
| 414 |    325.709953 |     63.422027 | Dean Schnabel                                                                                                                                                  |
| 415 |    692.078233 |     10.983672 | Andy Wilson                                                                                                                                                    |
| 416 |    617.117834 |    602.547999 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                         |
| 417 |    233.364384 |     14.012290 | Zimices                                                                                                                                                        |
| 418 |    490.681217 |     11.881303 | Zimices                                                                                                                                                        |
| 419 |    262.216666 |     21.551284 | Smokeybjb                                                                                                                                                      |
| 420 |     18.598579 |    300.957968 | Felix Vaux                                                                                                                                                     |
| 421 |    455.547491 |    690.511219 | Matt Crook                                                                                                                                                     |
| 422 |    333.277548 |    761.502159 | Melissa Broussard                                                                                                                                              |
| 423 |    386.470555 |    656.078831 | Tracy A. Heath                                                                                                                                                 |
| 424 |    259.024298 |    171.906461 | Steven Traver                                                                                                                                                  |
| 425 |    635.967990 |    698.873734 | Tasman Dixon                                                                                                                                                   |
| 426 |    699.866486 |    240.737884 | Tyler Greenfield                                                                                                                                               |
| 427 |    821.379876 |    790.825546 | NA                                                                                                                                                             |
| 428 |    541.497623 |     76.716745 | Jimmy Bernot                                                                                                                                                   |
| 429 |    580.803265 |    570.361624 | Lafage                                                                                                                                                         |
| 430 |    622.813352 |     14.350830 | Jagged Fang Designs                                                                                                                                            |
| 431 |    969.891490 |    593.653107 | Scott Hartman                                                                                                                                                  |
| 432 |    406.086050 |    211.458769 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 433 |    847.441619 |    489.173358 | Kanchi Nanjo                                                                                                                                                   |
| 434 |    400.225132 |    271.003227 | Trond R. Oskars                                                                                                                                                |
| 435 |    563.423502 |    562.894204 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 436 |    926.050841 |    726.883584 | Juan Carlos Jerí                                                                                                                                               |
| 437 |    573.158903 |    474.778477 | NA                                                                                                                                                             |
| 438 |    449.750880 |    259.607533 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
| 439 |    416.100397 |    409.625228 | Zimices                                                                                                                                                        |
| 440 |    672.324315 |    353.176894 | Maija Karala                                                                                                                                                   |
| 441 |    315.944618 |     15.192109 | Gareth Monger                                                                                                                                                  |
| 442 |    990.598428 |     16.114508 | Erika Schumacher                                                                                                                                               |
| 443 |    929.168998 |    583.483813 | T. Michael Keesey                                                                                                                                              |
| 444 |    383.060022 |    735.270331 | Matt Crook                                                                                                                                                     |
| 445 |    218.034389 |    227.198812 | Birgit Lang                                                                                                                                                    |
| 446 |    567.659351 |    467.821967 | Chuanixn Yu                                                                                                                                                    |
| 447 |    999.782177 |    579.118513 | Margot Michaud                                                                                                                                                 |
| 448 |    882.464378 |    493.327282 | Scott Hartman                                                                                                                                                  |
| 449 |    112.095754 |    481.148617 | Zimices                                                                                                                                                        |
| 450 |   1000.023133 |    371.858748 | Carlos Cano-Barbacil                                                                                                                                           |
| 451 |      9.439316 |    530.507271 | Emily Willoughby                                                                                                                                               |
| 452 |    415.060233 |    230.684924 | Steven Traver                                                                                                                                                  |
| 453 |    872.026051 |    303.522537 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                  |
| 454 |    285.866463 |    638.123507 | S.Martini                                                                                                                                                      |
| 455 |    587.715084 |    705.610138 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                           |
| 456 |    120.651494 |    384.257752 | Tauana J. Cunha                                                                                                                                                |
| 457 |    194.057679 |    423.409955 | Gabriela Palomo-Munoz                                                                                                                                          |
| 458 |    599.468741 |    620.327661 | Jessica Anne Miller                                                                                                                                            |
| 459 |    111.134637 |    561.832258 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                        |
| 460 |    667.020366 |     32.543405 | Noah Schlottman, photo by Casey Dunn                                                                                                                           |
| 461 |    871.169226 |    777.743901 | Steven Traver                                                                                                                                                  |
| 462 |    915.458559 |    785.300900 | NA                                                                                                                                                             |
| 463 |    687.144759 |    738.058020 | Abraão Leite                                                                                                                                                   |
| 464 |    469.501482 |    264.058965 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                            |
| 465 |    388.716477 |    126.305573 | Steven Traver                                                                                                                                                  |
| 466 |    490.340650 |    289.943723 | Gareth Monger                                                                                                                                                  |
| 467 |    505.734710 |      8.015303 | Erika Schumacher                                                                                                                                               |
| 468 |   1000.180966 |    668.920079 | Tauana J. Cunha                                                                                                                                                |
| 469 |    863.128239 |    376.169162 | Harold N Eyster                                                                                                                                                |
| 470 |    829.532940 |    277.048309 | Steven Traver                                                                                                                                                  |
| 471 |    861.299440 |      6.552887 | Erika Schumacher                                                                                                                                               |
| 472 |     19.587806 |    214.574606 | Claus Rebler                                                                                                                                                   |
| 473 |    488.118987 |    441.402998 | Terpsichores                                                                                                                                                   |
| 474 |    780.429831 |    687.148378 | Matt Crook                                                                                                                                                     |
| 475 |    512.888068 |    326.460377 | Margot Michaud                                                                                                                                                 |
| 476 |    405.374338 |    382.631018 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 477 |    846.824311 |    511.104414 | Zimices                                                                                                                                                        |
| 478 |    383.689980 |    698.453513 | Gabriela Palomo-Munoz                                                                                                                                          |
| 479 |    779.446897 |    304.260580 | Steven Traver                                                                                                                                                  |
| 480 |    669.136708 |    517.032230 | Gopal Murali                                                                                                                                                   |
| 481 |    399.160671 |    225.543035 | Matt Dempsey                                                                                                                                                   |
| 482 |    858.843878 |    411.101895 | Jagged Fang Designs                                                                                                                                            |
| 483 |    736.587987 |     87.728051 | NA                                                                                                                                                             |
| 484 |    502.178891 |    626.096973 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                  |
| 485 |    613.984672 |    237.374633 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 486 |    315.587373 |    369.567427 | Christine Axon                                                                                                                                                 |
| 487 |    217.593206 |    657.637330 | Sarah Alewijnse                                                                                                                                                |
| 488 |    713.852882 |    172.064805 | Gareth Monger                                                                                                                                                  |
| 489 |    308.681326 |    471.216225 | Shyamal                                                                                                                                                        |
| 490 |    977.300625 |    389.492137 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                     |
| 491 |    289.287077 |     11.690787 | Birgit Lang                                                                                                                                                    |
| 492 |     24.055005 |    202.593223 | Juan Carlos Jerí                                                                                                                                               |
| 493 |    150.668991 |    315.606955 | Margot Michaud                                                                                                                                                 |
| 494 |    639.650830 |    242.994134 | Ferran Sayol                                                                                                                                                   |
| 495 |    545.688975 |      5.086664 | FunkMonk                                                                                                                                                       |
| 496 |    854.656320 |    715.444915 | NA                                                                                                                                                             |
| 497 |    315.459623 |    381.143000 | Jagged Fang Designs                                                                                                                                            |
| 498 |    669.717676 |    738.177821 | Agnello Picorelli                                                                                                                                              |
| 499 |    947.283454 |    731.195649 | NA                                                                                                                                                             |
| 500 |     41.591769 |    151.764271 | Henry Lydecker                                                                                                                                                 |
| 501 |    678.377215 |    328.772465 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                  |
| 502 |    364.631184 |    288.670495 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 503 |    233.207747 |    752.677496 | Tracy A. Heath                                                                                                                                                 |
| 504 |     75.928271 |     72.543246 | Andy Wilson                                                                                                                                                    |
| 505 |    836.047891 |    550.221415 | Ferran Sayol                                                                                                                                                   |
| 506 |   1007.762398 |    525.758910 | Zimices                                                                                                                                                        |
| 507 |     41.346154 |    395.403539 | Zimices                                                                                                                                                        |
| 508 |    100.969123 |    166.712813 | Dean Schnabel                                                                                                                                                  |
| 509 |     93.727448 |     84.676077 | Andy Wilson                                                                                                                                                    |
| 510 |    187.731171 |    434.520042 | Oscar Sanisidro                                                                                                                                                |
| 511 |    562.904628 |    350.650769 | Sharon Wegner-Larsen                                                                                                                                           |
| 512 |     27.516504 |    111.757327 | Scott Hartman                                                                                                                                                  |
| 513 |    470.748383 |    642.633471 | Jagged Fang Designs                                                                                                                                            |
| 514 |    884.158889 |    287.168332 | Matt Crook                                                                                                                                                     |
| 515 |    453.440405 |    743.064761 | Alex Slavenko                                                                                                                                                  |
| 516 |    788.266590 |    151.104459 | Andy Wilson                                                                                                                                                    |
| 517 |    984.423612 |    406.154597 | Jagged Fang Designs                                                                                                                                            |
| 518 |    252.210883 |    418.046035 | Zimices                                                                                                                                                        |
| 519 |     70.035519 |    486.784461 | T. Michael Keesey                                                                                                                                              |
| 520 |     91.776357 |    102.129747 | Kamil S. Jaron                                                                                                                                                 |
| 521 |    138.893291 |    295.284709 | NA                                                                                                                                                             |
| 522 |    946.815625 |     27.547188 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                              |
| 523 |    372.843226 |    333.702642 | Matt Crook                                                                                                                                                     |
| 524 |    989.641769 |    169.718274 | Chris huh                                                                                                                                                      |
| 525 |    209.774087 |    678.590846 | Tess Linden                                                                                                                                                    |
| 526 |    758.160737 |    385.416099 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                |
| 527 |    818.536538 |     82.901183 | Jagged Fang Designs                                                                                                                                            |
| 528 |    105.376161 |    212.235144 | Birgit Lang                                                                                                                                                    |
| 529 |    773.663454 |    222.409373 | Melissa Broussard                                                                                                                                              |
| 530 |    425.718276 |    550.282752 | Jagged Fang Designs                                                                                                                                            |
| 531 |    449.015079 |     21.275817 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                              |
| 532 |     90.921972 |    482.708693 | NA                                                                                                                                                             |
| 533 |   1004.752816 |    735.904415 | Steven Traver                                                                                                                                                  |
| 534 |    960.019714 |    643.972965 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 535 |    770.930566 |    124.512947 | Ferran Sayol                                                                                                                                                   |
| 536 |    797.920016 |    129.853155 | NA                                                                                                                                                             |
| 537 |    652.798002 |    157.127294 | Tasman Dixon                                                                                                                                                   |
| 538 |    895.826019 |    487.528125 | Ignacio Contreras                                                                                                                                              |
| 539 |   1015.358921 |    767.595130 | Ferran Sayol                                                                                                                                                   |
| 540 |    126.474268 |    640.306853 | Renato de Carvalho Ferreira                                                                                                                                    |
| 541 |    765.626363 |    591.473040 | Gabriela Palomo-Munoz                                                                                                                                          |
| 542 |    416.297958 |    397.981948 | Gareth Monger                                                                                                                                                  |
| 543 |    432.885992 |    334.083195 | Steven Traver                                                                                                                                                  |
| 544 |    943.077496 |    375.665994 | NA                                                                                                                                                             |
| 545 |   1012.010279 |    716.476341 | Gareth Monger                                                                                                                                                  |
| 546 |    492.613841 |     22.052109 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 547 |    374.627151 |    667.162572 | Diana Pomeroy                                                                                                                                                  |
| 548 |    629.018265 |    420.620203 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                  |
| 549 |    234.311464 |    169.041276 | C. Camilo Julián-Caballero                                                                                                                                     |
| 550 |    893.976024 |    556.940108 | Chase Brownstein                                                                                                                                               |
| 551 |    183.640393 |    704.221997 | Zimices                                                                                                                                                        |
| 552 |    104.060099 |    657.520252 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                |
| 553 |    254.131684 |     77.159588 | Alexandre Vong                                                                                                                                                 |
| 554 |    122.028170 |     68.578477 | Alexandre Vong                                                                                                                                                 |
| 555 |    975.358416 |    688.765288 | Zimices                                                                                                                                                        |
| 556 |    869.969482 |    462.094553 | Matt Crook                                                                                                                                                     |
| 557 |    402.148576 |    402.583629 | Michael P. Taylor                                                                                                                                              |
| 558 |    444.961121 |    178.858445 | Gabriela Palomo-Munoz                                                                                                                                          |
| 559 |    613.653017 |    635.855692 | T. Michael Keesey                                                                                                                                              |
| 560 |    501.768686 |    585.173240 | Gareth Monger                                                                                                                                                  |
| 561 |     19.140824 |    646.931734 | xgirouxb                                                                                                                                                       |
| 562 |    811.210064 |    368.800858 | Steven Traver                                                                                                                                                  |
| 563 |    354.993544 |    557.940771 | Ferran Sayol                                                                                                                                                   |
| 564 |    535.197197 |     93.113456 | Emily Willoughby                                                                                                                                               |
| 565 |    763.495866 |    553.684297 | Zimices                                                                                                                                                        |
| 566 |    802.569532 |    393.841609 | Ricardo Araújo                                                                                                                                                 |
| 567 |    514.425909 |     23.049346 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                 |
| 568 |    434.564958 |    763.925688 | NA                                                                                                                                                             |
| 569 |    636.425589 |    711.381300 | Collin Gross                                                                                                                                                   |
| 570 |     15.930618 |    768.866861 | L. Shyamal                                                                                                                                                     |
| 571 |    169.410869 |    630.348423 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                     |
| 572 |    370.673094 |    731.714422 | Chris huh                                                                                                                                                      |
| 573 |    873.393526 |    717.520684 | T. Michael Keesey                                                                                                                                              |
| 574 |    400.847529 |    708.361120 | Zimices                                                                                                                                                        |
| 575 |    599.918759 |    290.737687 | Chris huh                                                                                                                                                      |
| 576 |    109.935502 |    198.009028 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 577 |     56.968369 |     66.733078 | Margot Michaud                                                                                                                                                 |
| 578 |    528.785597 |    375.528146 | T. Michael Keesey (photo by Sean Mack)                                                                                                                         |
| 579 |    403.212084 |    411.707185 | Alexandre Vong                                                                                                                                                 |
| 580 |    467.345244 |     33.009341 | Katie S. Collins                                                                                                                                               |
| 581 |    161.397313 |    702.683445 | Markus A. Grohme                                                                                                                                               |
| 582 |     29.489041 |    288.407674 | Jack Mayer Wood                                                                                                                                                |
| 583 |    930.801845 |    578.141282 | Gareth Monger                                                                                                                                                  |
| 584 |     10.661272 |    361.622538 | Dean Schnabel                                                                                                                                                  |
| 585 |    933.900873 |    557.171944 | Felix Vaux and Steven A. Trewick                                                                                                                               |
| 586 |    940.618028 |    721.755674 | Jessica Anne Miller                                                                                                                                            |
| 587 |    565.536910 |    194.957708 | CNZdenek                                                                                                                                                       |
| 588 |   1008.608945 |    419.593536 | Zimices                                                                                                                                                        |
| 589 |     51.824523 |    457.479853 | Jagged Fang Designs                                                                                                                                            |
| 590 |    677.560317 |    159.744880 | Mathieu Basille                                                                                                                                                |
| 591 |     53.503802 |    743.565288 | Melissa Ingala                                                                                                                                                 |
| 592 |    282.124790 |    736.594155 | Margot Michaud                                                                                                                                                 |
| 593 |    681.266717 |    165.639219 | Markus A. Grohme                                                                                                                                               |
| 594 |     44.456918 |    421.181272 | Zimices                                                                                                                                                        |
| 595 |    375.925154 |    116.222848 | Margot Michaud                                                                                                                                                 |
| 596 |    609.186553 |     91.619557 | Matt Crook                                                                                                                                                     |
| 597 |    142.075392 |    520.750206 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 598 |    841.687253 |    644.592070 | Andy Wilson                                                                                                                                                    |
| 599 |    809.716759 |    648.383398 | Erika Schumacher                                                                                                                                               |
| 600 |    382.404105 |    371.373908 | Zimices                                                                                                                                                        |
| 601 |    486.375583 |    489.187386 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 602 |    865.722052 |    218.166007 | Zimices                                                                                                                                                        |
| 603 |     44.828147 |    687.610073 | Zimices                                                                                                                                                        |
| 604 |    648.836971 |    140.522026 | Matt Dempsey                                                                                                                                                   |
| 605 |    820.242958 |    298.903242 | Gareth Monger                                                                                                                                                  |
| 606 |    478.806371 |    167.196371 | Steven Traver                                                                                                                                                  |
| 607 |     13.509146 |    693.701505 | Shyamal                                                                                                                                                        |
| 608 |    693.968566 |    544.740446 | Markus A. Grohme                                                                                                                                               |
| 609 |     83.222899 |    504.513736 | Pete Buchholz                                                                                                                                                  |
| 610 |    671.730454 |    642.934385 | Jagged Fang Designs                                                                                                                                            |
| 611 |     94.835036 |    707.860142 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                              |
| 612 |   1003.424097 |    434.034651 | Chuanixn Yu                                                                                                                                                    |
| 613 |    868.617404 |    561.382994 | Gareth Monger                                                                                                                                                  |
| 614 |    125.135822 |    147.687688 | Mathilde Cordellier                                                                                                                                            |
| 615 |    359.692700 |    429.363883 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 616 |    386.671910 |    689.785551 | Margot Michaud                                                                                                                                                 |
| 617 |    815.845999 |    393.232978 | Gabriela Palomo-Munoz                                                                                                                                          |
| 618 |    641.350955 |    306.273537 | Steven Traver                                                                                                                                                  |
| 619 |    327.841874 |     83.268058 | Carlos Cano-Barbacil                                                                                                                                           |
| 620 |    592.261642 |    425.605504 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 621 |    283.775947 |    131.563290 | Margot Michaud                                                                                                                                                 |
| 622 |    922.071655 |    300.012555 | Emily Willoughby                                                                                                                                               |
| 623 |     57.006475 |    135.469384 | Beth Reinke                                                                                                                                                    |
| 624 |    233.162667 |    383.400661 | Zimices                                                                                                                                                        |
| 625 |     26.825821 |    427.601266 | Steven Traver                                                                                                                                                  |
| 626 |    709.566521 |    224.530012 | NA                                                                                                                                                             |
| 627 |    272.654259 |      6.245277 | Zimices                                                                                                                                                        |
| 628 |    829.182246 |    723.066671 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 629 |    210.330512 |    777.963111 | Matt Crook                                                                                                                                                     |
| 630 |     41.798899 |    716.085754 | Michael P. Taylor                                                                                                                                              |
| 631 |    490.927165 |    294.423735 | Scott Hartman                                                                                                                                                  |
| 632 |    854.664066 |    580.936150 | Matt Crook                                                                                                                                                     |
| 633 |    852.847642 |    298.906125 | C. Camilo Julián-Caballero                                                                                                                                     |
| 634 |   1015.253423 |    198.589453 | Matt Crook                                                                                                                                                     |
| 635 |    296.745783 |    350.900386 | Steven Traver                                                                                                                                                  |
| 636 |    258.300334 |    794.407087 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                |
| 637 |    787.336306 |    338.791807 | Michelle Site                                                                                                                                                  |
| 638 |    129.240655 |    529.092691 | Shyamal                                                                                                                                                        |
| 639 |    465.404618 |     25.956674 | Steven Coombs                                                                                                                                                  |
| 640 |    166.576017 |    224.146064 | Michelle Site                                                                                                                                                  |
| 641 |    755.743147 |    264.009669 | NA                                                                                                                                                             |
| 642 |    361.761753 |    706.881540 | Riccardo Percudani                                                                                                                                             |
| 643 |    246.446589 |     43.917185 | Gareth Monger                                                                                                                                                  |
| 644 |    648.909496 |    724.700876 | Gabriela Palomo-Munoz                                                                                                                                          |
| 645 |    795.218564 |    483.148663 | Jakovche                                                                                                                                                       |
| 646 |    888.159783 |    201.745185 | Chris huh                                                                                                                                                      |
| 647 |    396.486414 |    205.620966 | Shyamal                                                                                                                                                        |
| 648 |    949.726358 |    528.144142 | Ignacio Contreras                                                                                                                                              |
| 649 |    833.437508 |     23.624566 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                               |
| 650 |    548.154609 |    151.870463 | Sharon Wegner-Larsen                                                                                                                                           |
| 651 |    213.989640 |    406.936509 | Ghedoghedo, vectorized by Zimices                                                                                                                              |
| 652 |    251.180508 |    652.826167 | Zimices                                                                                                                                                        |
| 653 |    473.088277 |    610.792728 | Matt Crook                                                                                                                                                     |
| 654 |    582.786015 |    465.536710 | Scott Hartman                                                                                                                                                  |
| 655 |    344.694683 |     81.051859 | Gareth Monger                                                                                                                                                  |
| 656 |    149.562161 |    193.948004 | Andy Wilson                                                                                                                                                    |
| 657 |    193.867979 |    399.605658 | Jagged Fang Designs                                                                                                                                            |
| 658 |    996.729592 |    716.379784 | Margot Michaud                                                                                                                                                 |
| 659 |    303.589101 |    377.220082 | Gareth Monger                                                                                                                                                  |
| 660 |    124.915222 |    161.086305 | Zimices                                                                                                                                                        |
| 661 |    496.543191 |    499.285603 | Margot Michaud                                                                                                                                                 |
| 662 |    144.070521 |    733.054319 | NA                                                                                                                                                             |
| 663 |    155.472528 |    139.008636 | Ingo Braasch                                                                                                                                                   |
| 664 |    131.821775 |    245.507331 | Andy Wilson                                                                                                                                                    |
| 665 |    188.362090 |    404.244362 | Scott Hartman                                                                                                                                                  |
| 666 |    583.679351 |     96.028619 | Noah Schlottman                                                                                                                                                |
| 667 |     68.786802 |    378.722555 | Andy Wilson                                                                                                                                                    |
| 668 |    328.726453 |    571.951391 | Steven Traver                                                                                                                                                  |
| 669 |    970.827197 |    129.668500 | Mathilde Cordellier                                                                                                                                            |
| 670 |    411.078803 |    120.840806 | Beth Reinke                                                                                                                                                    |
| 671 |    290.535326 |    786.213421 | John Gould (vectorized by T. Michael Keesey)                                                                                                                   |
| 672 |    620.618818 |    527.820027 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                 |
| 673 |    685.196247 |    691.434251 | Margot Michaud                                                                                                                                                 |
| 674 |    374.492015 |    198.575129 | Renato de Carvalho Ferreira                                                                                                                                    |
| 675 |    690.037616 |    396.512832 | Matt Crook                                                                                                                                                     |
| 676 |    607.118792 |    185.970253 | Jaime Headden                                                                                                                                                  |
| 677 |    720.725757 |    216.925520 | Noah Schlottman, photo by Adam G. Clause                                                                                                                       |
| 678 |    812.301832 |     39.951889 | Ferran Sayol                                                                                                                                                   |
| 679 |    532.301596 |    548.169811 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                            |
| 680 |    501.579247 |    699.539916 | NA                                                                                                                                                             |
| 681 |    805.712564 |    561.550720 | Jagged Fang Designs                                                                                                                                            |
| 682 |    208.931535 |     23.258495 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                    |
| 683 |    167.758361 |    442.645167 | Kamil S. Jaron                                                                                                                                                 |
| 684 |    344.883556 |    109.656444 | T. Michael Keesey                                                                                                                                              |
| 685 |    780.877608 |    587.016752 | Maija Karala                                                                                                                                                   |
| 686 |    649.102534 |    462.744950 | FunkMonk                                                                                                                                                       |
| 687 |   1017.635802 |    485.062281 | Christoph Schomburg                                                                                                                                            |
| 688 |    939.831803 |    277.474848 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                |
| 689 |    609.965857 |    417.872906 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                          |
| 690 |    271.931477 |    115.239689 | Gabriela Palomo-Munoz                                                                                                                                          |
| 691 |    878.851442 |     68.248858 | Sarah Werning                                                                                                                                                  |
| 692 |    671.145269 |    768.407175 | Mali’o Kodis, photograph by G. Giribet                                                                                                                         |
| 693 |    127.045016 |    490.894998 | Ben Liebeskind                                                                                                                                                 |
| 694 |     53.144987 |    314.830311 | Margot Michaud                                                                                                                                                 |
| 695 |    977.009509 |    595.597609 | Chris huh                                                                                                                                                      |
| 696 |    815.888550 |    709.795000 | Maija Karala                                                                                                                                                   |
| 697 |    603.780438 |     21.737195 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                               |
| 698 |     46.135831 |    759.424773 | Rene Martin                                                                                                                                                    |
| 699 |     61.893767 |     77.005246 | Zimices                                                                                                                                                        |
| 700 |    573.928887 |    424.159429 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 701 |    410.574019 |    761.959016 | Matt Crook                                                                                                                                                     |
| 702 |    952.076007 |    615.840640 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 703 |    544.283521 |    299.932234 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                             |
| 704 |    650.813333 |    365.624001 | Zimices                                                                                                                                                        |
| 705 |    613.022896 |    727.347732 | T. Michael Keesey                                                                                                                                              |
| 706 |    407.435921 |    167.682966 | Christoph Schomburg                                                                                                                                            |
| 707 |    951.726833 |    495.061140 | Gabriela Palomo-Munoz                                                                                                                                          |
| 708 |    307.462053 |     27.560065 | Markus A. Grohme                                                                                                                                               |
| 709 |     76.067379 |    131.047125 | Chuanixn Yu                                                                                                                                                    |
| 710 |     23.149051 |    176.472750 | Michelle Site                                                                                                                                                  |
| 711 |    563.363240 |    176.388417 | Zimices                                                                                                                                                        |
| 712 |    816.407888 |    158.240747 | Rafael Maia                                                                                                                                                    |
| 713 |    572.469808 |    768.481741 | Margot Michaud                                                                                                                                                 |
| 714 |    244.316142 |    671.420166 | Zimices                                                                                                                                                        |
| 715 |    440.492250 |    696.502696 | Gabriela Palomo-Munoz                                                                                                                                          |
| 716 |    863.505664 |    230.616401 | Matt Crook                                                                                                                                                     |
| 717 |    921.639367 |     64.178425 | Gareth Monger                                                                                                                                                  |
| 718 |    378.053608 |      7.660416 | NA                                                                                                                                                             |
| 719 |    343.872038 |    485.237131 | NA                                                                                                                                                             |
| 720 |    801.277134 |    731.437813 | Patrick Strutzenberger                                                                                                                                         |
| 721 |    697.865268 |     62.518755 | Hans Hillewaert                                                                                                                                                |
| 722 |    998.492128 |    454.259704 | Matt Crook                                                                                                                                                     |
| 723 |    670.048625 |    461.126527 | Gabriela Palomo-Munoz                                                                                                                                          |
| 724 |    641.624276 |    130.438559 | Zimices                                                                                                                                                        |
| 725 |    782.444341 |    329.069800 | Zimices                                                                                                                                                        |
| 726 |    863.456381 |     99.443775 | Renato Santos                                                                                                                                                  |
| 727 |    168.032461 |    370.261758 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                    |
| 728 |    808.881520 |     15.872524 | Steven Traver                                                                                                                                                  |
| 729 |     42.428642 |    267.141867 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                          |
| 730 |    398.987791 |    628.359687 | Yan Wong from photo by Denes Emoke                                                                                                                             |
| 731 |    420.461790 |    135.759200 | Margot Michaud                                                                                                                                                 |
| 732 |    786.741469 |    569.103934 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                              |
| 733 |    415.366392 |    258.920297 | Gareth Monger                                                                                                                                                  |
| 734 |    757.086558 |    655.492634 | Michele M Tobias                                                                                                                                               |
| 735 |    634.828994 |    691.196714 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                 |
| 736 |    262.284775 |    755.865825 | T. Michael Keesey                                                                                                                                              |
| 737 |    855.503011 |    205.591184 | Zimices                                                                                                                                                        |
| 738 |    794.591616 |    166.828379 | Chris huh                                                                                                                                                      |
| 739 |    943.619923 |    288.006933 | Lily Hughes                                                                                                                                                    |
| 740 |    607.506447 |    676.944125 | Zimices                                                                                                                                                        |
| 741 |    823.440532 |    701.506812 | Erika Schumacher                                                                                                                                               |
| 742 |     14.479913 |    100.315810 | FJDegrange                                                                                                                                                     |
| 743 |    517.134304 |    514.752064 | Kelly                                                                                                                                                          |
| 744 |    206.763560 |    694.908343 | Steven Traver                                                                                                                                                  |
| 745 |    417.977732 |    459.225570 | NA                                                                                                                                                             |
| 746 |    400.749934 |    157.946471 | Chris huh                                                                                                                                                      |
| 747 |     21.435389 |    136.786562 | Ignacio Contreras                                                                                                                                              |
| 748 |    581.995038 |    231.805138 | Scott Hartman                                                                                                                                                  |
| 749 |     86.909328 |    215.340176 | Bennet McComish, photo by Hans Hillewaert                                                                                                                      |
| 750 |     14.802137 |    731.253143 | Gabriela Palomo-Munoz                                                                                                                                          |
| 751 |    256.570061 |    441.533602 | Markus A. Grohme                                                                                                                                               |
| 752 |     34.559784 |    297.312888 | FunkMonk                                                                                                                                                       |
| 753 |   1013.695970 |    668.942982 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 754 |    863.563545 |    702.657466 | Jaime Headden                                                                                                                                                  |
| 755 |    606.698498 |      9.568939 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 756 |    129.689068 |    731.677422 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                          |
| 757 |    269.031812 |    192.672943 | Margot Michaud                                                                                                                                                 |
| 758 |    202.632160 |    704.350826 | Shyamal                                                                                                                                                        |
| 759 |    277.688676 |    751.024325 | Collin Gross                                                                                                                                                   |
| 760 |    432.127601 |    745.609822 | Gabriela Palomo-Munoz                                                                                                                                          |
| 761 |    331.897486 |    337.717861 | Tracy A. Heath                                                                                                                                                 |
| 762 |    996.761955 |    774.515281 | Ferran Sayol                                                                                                                                                   |
| 763 |     88.694280 |    132.790642 | C. Camilo Julián-Caballero                                                                                                                                     |
| 764 |    623.839927 |    619.540058 | T. Michael Keesey                                                                                                                                              |
| 765 |    700.423758 |    620.325619 | Jagged Fang Designs                                                                                                                                            |
| 766 |    504.523539 |    667.940583 | Scott Hartman                                                                                                                                                  |
| 767 |    803.821362 |    582.281302 | C. Camilo Julián-Caballero                                                                                                                                     |
| 768 |    844.105615 |    634.104555 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                  |
| 769 |    827.438540 |     38.064371 | David Orr                                                                                                                                                      |
| 770 |    183.386990 |    145.900673 | Markus A. Grohme                                                                                                                                               |
| 771 |    996.521370 |    141.277462 | Andy Wilson                                                                                                                                                    |
| 772 |    878.268378 |    385.700923 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                        |
| 773 |    818.192769 |    693.435849 | Ferran Sayol                                                                                                                                                   |
| 774 |    995.675305 |    555.715673 | Matt Crook                                                                                                                                                     |
| 775 |    898.659551 |    116.489837 | C. Camilo Julián-Caballero                                                                                                                                     |
| 776 |    265.696688 |    481.852812 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                |
| 777 |    154.043292 |    753.410906 | Matt Crook                                                                                                                                                     |
| 778 |    334.765645 |    365.983715 | Tasman Dixon                                                                                                                                                   |
| 779 |     64.283990 |    508.666132 | Margot Michaud                                                                                                                                                 |
| 780 |    329.151407 |    133.531201 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                       |
| 781 |    384.894970 |    401.990872 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                     |
| 782 |    274.648334 |    220.947614 | NA                                                                                                                                                             |
| 783 |    789.367172 |    438.502109 | NASA                                                                                                                                                           |
| 784 |    143.086367 |    261.821084 | Henry Lydecker                                                                                                                                                 |
| 785 |    837.169242 |    381.653004 | NA                                                                                                                                                             |
| 786 |    564.761352 |    518.490398 | Chris huh                                                                                                                                                      |
| 787 |      4.638397 |    425.272975 | Falconaumanni and T. Michael Keesey                                                                                                                            |
| 788 |     26.056288 |     38.824118 | Matt Crook                                                                                                                                                     |
| 789 |    665.887911 |    138.655826 | Joanna Wolfe                                                                                                                                                   |
| 790 |    601.884669 |    647.929908 | Margot Michaud                                                                                                                                                 |
| 791 |    473.646169 |    499.483455 | Gabriela Palomo-Munoz                                                                                                                                          |
| 792 |    989.476241 |    106.453982 | NA                                                                                                                                                             |
| 793 |    883.390404 |    499.004749 | Jagged Fang Designs                                                                                                                                            |
| 794 |    505.094973 |    723.010106 | NASA                                                                                                                                                           |
| 795 |     15.654321 |    417.220270 | Lukasiniho                                                                                                                                                     |
| 796 |    132.541874 |    507.512567 | Gareth Monger                                                                                                                                                  |
| 797 |    635.166223 |    647.085794 | Charles R. Knight, vectorized by Zimices                                                                                                                       |
| 798 |    852.464007 |    653.173964 | C. Camilo Julián-Caballero                                                                                                                                     |
| 799 |    568.834037 |    238.653610 | Markus A. Grohme                                                                                                                                               |
| 800 |    236.270613 |    221.110654 | NA                                                                                                                                                             |
| 801 |    302.895589 |    445.013751 | Gareth Monger                                                                                                                                                  |
| 802 |    223.436769 |    430.709581 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                         |
| 803 |    950.109568 |    715.412975 | Matus Valach                                                                                                                                                   |
| 804 |    198.582050 |    758.385311 | Matt Crook                                                                                                                                                     |
| 805 |    213.952578 |    336.378373 | Melissa Broussard                                                                                                                                              |
| 806 |    407.644801 |    325.221710 | Jagged Fang Designs                                                                                                                                            |
| 807 |    101.394081 |    623.372709 | Matt Crook                                                                                                                                                     |
| 808 |    770.261261 |    658.190737 | Gareth Monger                                                                                                                                                  |
| 809 |    346.914700 |    655.493946 | NA                                                                                                                                                             |
| 810 |    407.084298 |    787.249813 | T. Michael Keesey                                                                                                                                              |
| 811 |    587.560797 |    160.386991 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                               |
| 812 |    927.644257 |    289.055543 | Lafage                                                                                                                                                         |
| 813 |    462.539089 |    541.100250 | L. Shyamal                                                                                                                                                     |
| 814 |    171.610827 |    659.887622 | Zimices                                                                                                                                                        |
| 815 |     67.324854 |    668.068703 | Trond R. Oskars                                                                                                                                                |
| 816 |    846.915394 |    226.791159 | Ignacio Contreras                                                                                                                                              |
| 817 |    129.679904 |    265.029774 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 818 |    272.587050 |    632.174646 | Scott Hartman                                                                                                                                                  |
| 819 |    830.078666 |    350.901863 | Steven Traver                                                                                                                                                  |
| 820 |     17.078661 |    676.505083 | Juan Carlos Jerí                                                                                                                                               |
| 821 |     26.948339 |    353.827149 | Zimices                                                                                                                                                        |
| 822 |    519.104386 |    532.964532 | Pedro de Siracusa                                                                                                                                              |
| 823 |    404.254594 |    664.968878 | Birgit Lang                                                                                                                                                    |
| 824 |    955.013177 |    790.684897 | James R. Spotila and Ray Chatterji                                                                                                                             |
| 825 |     23.925256 |    320.270051 | Kanchi Nanjo                                                                                                                                                   |
| 826 |     54.577490 |    633.760709 | Kamil S. Jaron                                                                                                                                                 |
| 827 |     59.857175 |     30.783878 | Matt Celeskey                                                                                                                                                  |
| 828 |    926.875148 |    775.830110 | Mareike C. Janiak                                                                                                                                              |
| 829 |    348.415727 |    504.878299 | Rene Martin                                                                                                                                                    |
| 830 |    999.720313 |    384.616966 | Jack Mayer Wood                                                                                                                                                |
| 831 |   1018.553309 |    167.370993 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey   |
| 832 |    493.345134 |    532.708365 | Andy Wilson                                                                                                                                                    |
| 833 |    337.134766 |    526.470154 | Noah Schlottman, photo by David J Patterson                                                                                                                    |
| 834 |    886.996203 |    373.426588 | Zimices                                                                                                                                                        |
| 835 |    769.151394 |    685.550576 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 836 |    251.329630 |    122.977090 | Ferran Sayol                                                                                                                                                   |
| 837 |    633.409841 |    259.501366 | Scott Hartman                                                                                                                                                  |
| 838 |    652.901094 |     84.614585 | Nobu Tamura                                                                                                                                                    |
| 839 |    167.980745 |    151.099849 | Ferran Sayol                                                                                                                                                   |
| 840 |    839.262950 |    200.195354 | Matt Crook                                                                                                                                                     |
| 841 |    206.117479 |    214.759358 | Eyal Bartov                                                                                                                                                    |
| 842 |    232.072830 |     93.800449 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                |
| 843 |    848.081567 |    723.090518 | NA                                                                                                                                                             |
| 844 |    491.969032 |    195.164691 | Birgit Lang                                                                                                                                                    |
| 845 |    212.744615 |     40.810066 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                              |
| 846 |    203.064122 |    481.705462 | Lily Hughes                                                                                                                                                    |
| 847 |    487.333576 |    582.761959 | Chris huh                                                                                                                                                      |
| 848 |    408.829027 |    458.426558 | Gareth Monger                                                                                                                                                  |
| 849 |    754.720177 |    332.480265 | Scott Hartman                                                                                                                                                  |
| 850 |    832.199792 |     48.572355 | Louis Ranjard                                                                                                                                                  |
| 851 |     54.985463 |     39.010076 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 852 |    261.738347 |    779.497882 | Aadx                                                                                                                                                           |
| 853 |     60.318325 |    100.230782 | Gareth Monger                                                                                                                                                  |
| 854 |     36.184886 |     44.102061 | Ferran Sayol                                                                                                                                                   |
| 855 |    437.085343 |    184.689369 | NA                                                                                                                                                             |
| 856 |   1008.489765 |    686.725626 | Matus Valach                                                                                                                                                   |
| 857 |    343.174687 |     63.119506 | Felix Vaux                                                                                                                                                     |
| 858 |    647.873232 |    412.513436 | André Karwath (vectorized by T. Michael Keesey)                                                                                                                |
| 859 |    735.260126 |    504.993048 | Joshua Fowler                                                                                                                                                  |
| 860 |    668.163490 |     55.474329 | Jiekun He                                                                                                                                                      |
| 861 |    392.346014 |     68.450019 | Felix Vaux                                                                                                                                                     |
| 862 |    858.125481 |    669.488126 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                  |
| 863 |     14.277053 |    384.705416 | Margot Michaud                                                                                                                                                 |
| 864 |    155.189058 |    743.429081 | Mathilde Cordellier                                                                                                                                            |
| 865 |    815.710011 |    169.844711 | Shyamal                                                                                                                                                        |
| 866 |    471.564532 |    791.428044 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                              |
| 867 |    130.861791 |    625.145488 | NA                                                                                                                                                             |
| 868 |    754.623534 |    314.968861 | Steven Traver                                                                                                                                                  |
| 869 |    347.605431 |     20.603652 | Gareth Monger                                                                                                                                                  |
| 870 |    941.249861 |    303.716485 | Gordon E. Robertson                                                                                                                                            |
| 871 |    468.906538 |    528.938287 | Pedro de Siracusa                                                                                                                                              |
| 872 |    882.325983 |    159.145699 | Steven Traver                                                                                                                                                  |
| 873 |    664.276326 |    256.850685 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                             |
| 874 |   1017.501217 |    564.873488 | Gareth Monger                                                                                                                                                  |
| 875 |    224.370842 |    202.115205 | Margot Michaud                                                                                                                                                 |
| 876 |    650.579325 |    698.430309 | Gabriela Palomo-Munoz                                                                                                                                          |
| 877 |    875.372379 |    341.225283 | Carlos Cano-Barbacil                                                                                                                                           |
| 878 |    340.098208 |    496.698936 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                     |
| 879 |   1008.622693 |    625.365793 | Shyamal                                                                                                                                                        |
| 880 |    351.710189 |    140.729465 | \[unknown\]                                                                                                                                                    |
| 881 |    866.609066 |    690.539621 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                   |
| 882 |    754.413443 |    598.230671 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 883 |    934.667499 |    242.005026 | Margot Michaud                                                                                                                                                 |
| 884 |    197.811907 |    785.645303 | Ferran Sayol                                                                                                                                                   |
| 885 |    791.131885 |    459.942973 | Gareth Monger                                                                                                                                                  |
| 886 |    157.391533 |    353.780566 | Matt Crook                                                                                                                                                     |
| 887 |     24.194257 |    698.930954 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 888 |    942.890681 |    139.390781 | Tasman Dixon                                                                                                                                                   |
| 889 |    146.981714 |    624.320126 | Margot Michaud                                                                                                                                                 |
| 890 |   1011.036839 |    189.184342 | Scott Hartman, modified by T. Michael Keesey                                                                                                                   |
| 891 |    619.430827 |     24.443048 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                 |
| 892 |    113.189262 |    630.781946 | Steven Traver                                                                                                                                                  |
| 893 |    813.510202 |    267.977540 | Gareth Monger                                                                                                                                                  |
| 894 |    682.609779 |    539.125332 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 895 |    143.489556 |    699.223629 | Emily Willoughby                                                                                                                                               |
| 896 |     77.062531 |    791.495624 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                |
| 897 |    292.557328 |    628.604957 | Margot Michaud                                                                                                                                                 |
| 898 |    117.750739 |    653.093316 | Mathieu Basille                                                                                                                                                |
| 899 |    574.791452 |     20.189521 | Sharon Wegner-Larsen                                                                                                                                           |
| 900 |    633.946416 |    596.780881 | Arthur S. Brum                                                                                                                                                 |
| 901 |    313.349992 |    179.333209 | Margot Michaud                                                                                                                                                 |
| 902 |    342.436585 |      7.417401 | Shyamal                                                                                                                                                        |
| 903 |   1003.098097 |    343.102222 | Mathew Wedel                                                                                                                                                   |
| 904 |    915.781310 |    568.468939 | T. Michael Keesey                                                                                                                                              |
| 905 |     89.252742 |    584.386004 | Maxime Dahirel                                                                                                                                                 |
| 906 |    863.190924 |    179.059078 | Jagged Fang Designs                                                                                                                                            |
| 907 |     17.699134 |    146.581316 | Steven Traver                                                                                                                                                  |

    #> Your tweet has been posted!
