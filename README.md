
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

Mali’o Kodis, photograph by Jim Vargo, Scott Hartman, Gareth Monger,
Christoph Schomburg, Shyamal, Margot Michaud, Ferran Sayol, Matt Crook,
Steven Traver, Sarah Werning, Beth Reinke, Jagged Fang Designs, Collin
Gross, Falconaumanni and T. Michael Keesey, André Karwath (vectorized by
T. Michael Keesey), Matthias Buschmann (vectorized by T. Michael
Keesey), Chase Brownstein, Xavier Giroux-Bougard, Pearson Scott Foresman
(vectorized by T. Michael Keesey), C. Camilo Julián-Caballero, Lily
Hughes, Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob
Slotow (vectorized by T. Michael Keesey), Nancy Wyman (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Robert Bruce
Horsfall, vectorized by Zimices, Dmitry Bogdanov (vectorized by T.
Michael Keesey), Robert Gay, modified from FunkMonk (Michael B.H.) and
T. Michael Keesey., Armin Reindl, Anthony Caravaggi, Lukasiniho, Owen
Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves), Nobu
Tamura (vectorized by T. Michael Keesey), Chris huh, Michael Scroggie,
from original photograph by Gary M. Stolz, USFWS (original photograph in
public domain)., Andrew A. Farke, Gabriela Palomo-Munoz, Ingo Braasch,
Felix Vaux, Emily Jane McTavish, Conty (vectorized by T. Michael
Keesey), Anna Willoughby, Rebecca Groom, Yan Wong, Birgit Lang, based on
a photo by D. Sikes, Tasman Dixon, Jaime Headden, Chuanixn Yu, Hanyong
Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang,
Jiming Zhang, Songhai Jia & T. Michael Keesey, Emily Willoughby, John
Curtis (vectorized by T. Michael Keesey), Zimices, H. F. O. March
(vectorized by T. Michael Keesey), FunkMonk, Mathew Wedel, Ignacio
Contreras, Esme Ashe-Jepson, Ian Burt (original) and T. Michael Keesey
(vectorization), Roberto Díaz Sibaja, ArtFavor & annaleeblysse, Scott
Hartman, modified by T. Michael Keesey, T. Michael Keesey, Mattia
Menchetti, Mattia Menchetti / Yan Wong, Zimices, based in Mauricio Antón
skeletal, JJ Harrison (vectorized by T. Michael Keesey), Ellen Edmonson
and Hugh Chrisp (vectorized by T. Michael Keesey), Sergio A.
Muñoz-Gómez, Markus A. Grohme, Frank Förster, Aline M. Ghilardi,
annaleeblysse, Chris Jennings (Risiatto), David Orr, Dmitry Bogdanov,
Sebastian Stabinger, Robert Gay, Michael Scroggie, Kai R. Caspar,
Michael Ströck (vectorized by T. Michael Keesey), Tauana J. Cunha, Maija
Karala, Lauren Sumner-Rooney, Ralf Janssen, Nikola-Michael Prpic & Wim
G. M. Damen (vectorized by T. Michael Keesey), Agnello Picorelli,
Ville-Veikko Sinkkonen, Scott Reid, Karina Garcia, Dori <dori@merr.info>
(source photo) and Nevit Dilmen, Smokeybjb (vectorized by T. Michael
Keesey), Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti,
Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G.
Barraclough (vectorized by T. Michael Keesey), Javier Luque, B. Duygu
Özpolat, Renato de Carvalho Ferreira, xgirouxb, Jimmy Bernot, Francesca
Belem Lopes Palmeira, T. Michael Keesey (from a photo by Maximilian
Paradiz), Didier Descouens (vectorized by T. Michael Keesey), Iain Reid,
Mali’o Kodis, photograph by Melissa Frey, Donovan Reginald Rosevear
(vectorized by T. Michael Keesey), Nobu Tamura, vectorized by Zimices,
Francesco Veronesi (vectorized by T. Michael Keesey), Griensteidl and T.
Michael Keesey, Bryan Carstens, Tracy A. Heath, Matthew E. Clapham,
Renata F. Martins, Kailah Thorn & Ben King, Michelle Site, Duane
Raver/USFWS, Julio Garza, Mariana Ruiz Villarreal, JCGiron, L. Shyamal,
Joe Schneid (vectorized by T. Michael Keesey), Smokeybjb, Matt
Martyniuk, Mali’o Kodis, photograph by G. Giribet, Abraão Leite, Robbie
N. Cada (vectorized by T. Michael Keesey), Harold N Eyster, Ricardo N.
Martinez & Oscar A. Alcober, Benchill, Ghedo (vectorized by T. Michael
Keesey), Karla Martinez, Alexander Schmidt-Lebuhn, Robert Bruce Horsfall
(vectorized by T. Michael Keesey), Brad McFeeters (vectorized by T.
Michael Keesey), Lafage, Neil Kelley, Maxime Dahirel (digitisation),
Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original
publication), Zimices / Julián Bayona, Ludwik Gasiorowski, Ellen
Edmonson (illustration) and Timothy J. Bartley (silhouette), Abraão B.
Leite, T. Michael Keesey (photo by J. M. Garg), Louis Ranjard, Caleb
Brown, Caleb M. Brown, Henry Lydecker, Hans Hillewaert (vectorized by T.
Michael Keesey), Kamil S. Jaron, Ghedoghedo (vectorized by T. Michael
Keesey), Matt Dempsey, Cesar Julian, SecretJellyMan - from Mason McNair,
Melissa Broussard, Rachel Shoop, Jose Carlos Arenas-Monroy, Sharon
Wegner-Larsen, George Edward Lodge (modified by T. Michael Keesey),
Obsidian Soul (vectorized by T. Michael Keesey), Madeleine Price Ball,
Noah Schlottman, photo from National Science Foundation - Turbellarian
Taxonomic Database, Cagri Cevrim, Christopher Laumer (vectorized by T.
Michael Keesey), Maxime Dahirel, Luis Cunha, Steven Coombs, A. H.
Baldwin (vectorized by T. Michael Keesey), Birgit Lang, T. Michael
Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees,
Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and
David W. Wrase (photography), John Gould (vectorized by T. Michael
Keesey), Florian Pfaff, Trond R. Oskars, Karkemish (vectorized by T.
Michael Keesey), CNZdenek, Milton Tan, M Kolmann, Joanna Wolfe,
Smokeybjb (modified by T. Michael Keesey), Konsta Happonen, from a
CC-BY-NC image by pelhonen on iNaturalist, Nobu Tamura, Michele M
Tobias, Jaime Headden, modified by T. Michael Keesey, T. Michael Keesey
(from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel
Vences), Cristina Guijarro, Crystal Maier, James Neenan, Dean Schnabel,
(after Spotila 2004), Dr. Thomas G. Barnes, USFWS, Richard J. Harris,
Terpsichores, Juan Carlos Jerí, Dein Freund der Baum (vectorized by T.
Michael Keesey), Farelli (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Daniel Stadtmauer, Martin R. Smith, B
Kimmel, Sarah Alewijnse, Pete Buchholz, T. Michael Keesey (after
Kukalová), Darren Naish (vectorized by T. Michael Keesey), Carlos
Cano-Barbacil, Julia B McHugh, RS, Oscar Sanisidro, Matthew Hooge
(vectorized by T. Michael Keesey), Mali’o Kodis, photograph by P. Funch
and R.M. Kristensen, Matt Martyniuk (vectorized by T. Michael Keesey),
FunkMonk (Michael B. H.), Apokryltaros (vectorized by T. Michael
Keesey), Fernando Campos De Domenico, Adrian Reich, Lisa M. “Pixxl”
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Emma Hughes, Richard Ruggiero, vectorized by Zimices, Keith
Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Jessica Anne Miller, Mo Hassan, Unknown (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Dinah Challen,
Jordan Mallon (vectorized by T. Michael Keesey), Giant Blue Anteater
(vectorized by T. Michael Keesey), Pedro de Siracusa, Bob Goldstein,
Vectorization:Jake Warner, Mario Quevedo, Michele Tobias, Mathilde
Cordellier, J. J. Harrison (photo) & T. Michael Keesey, Lukas Panzarin,
Óscar San-Isidro (vectorized by T. Michael Keesey), Michele M Tobias
from an image By Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Auckland
Museum, NASA, Andrew A. Farke, shell lines added by Yan Wong, Taro
Maeda, Alex Slavenko, Chris Hay, S.Martini, Raven Amos, Becky Barnes,
Matt Wilkins, Manabu Sakamoto, Lankester Edwin Ray (vectorized by T.
Michael Keesey), Tony Ayling (vectorized by T. Michael Keesey),
Baheerathan Murugavel,
\<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\>
(vectorized by T. Michael Keesey), Darren Naish (vectorize by T. Michael
Keesey), E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor &
Matthew J. Wedel), Robert Bruce Horsfall, from W.B. Scott’s 1912 “A
History of Land Mammals in the Western Hemisphere”, T. Michael Keesey
(after A. Y. Ivantsov), Mali’o Kodis, image from the Biodiversity
Heritage Library, Danny Cicchetti (vectorized by T. Michael Keesey), Y.
de Hoev. (vectorized by T. Michael Keesey), terngirl, E. J. Van
Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael
Keesey), Noah Schlottman, photo by Antonio Guillén, Michael P. Taylor, J
Levin W (illustration) and T. Michael Keesey (vectorization), Tim
Bertelink (modified by T. Michael Keesey), Jennifer Trimble, Alexandra
van der Geer, Mali’o Kodis, image by Rebecca Ritger, Michael “FunkMonk”
B. H. (vectorized by T. Michael Keesey), T. Michael Keesey (after Colin
M. L. Burnett), Arthur S. Brum, Smokeybjb, vectorized by Zimices, Katie
S. Collins, Myriam\_Ramirez, DW Bapst (modified from Bulman, 1970),
Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey
(vectorization), Konsta Happonen, from a CC-BY-NC image by sokolkov2002
on iNaturalist, Lee Harding (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Stanton F. Fink (vectorized by T.
Michael Keesey), Tyler Greenfield

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    417.424607 |    301.505262 | Mali’o Kodis, photograph by Jim Vargo                                                                                                                                                |
|   2 |    251.365469 |    340.228722 | Scott Hartman                                                                                                                                                                        |
|   3 |    351.197982 |    749.961211 | Gareth Monger                                                                                                                                                                        |
|   4 |    876.290516 |    554.068213 | NA                                                                                                                                                                                   |
|   5 |    230.501450 |    406.639318 | Christoph Schomburg                                                                                                                                                                  |
|   6 |    667.698611 |    578.359163 | Shyamal                                                                                                                                                                              |
|   7 |    213.655963 |     50.894650 | Margot Michaud                                                                                                                                                                       |
|   8 |    108.923746 |    196.197939 | Ferran Sayol                                                                                                                                                                         |
|   9 |     61.165020 |    504.716105 | Matt Crook                                                                                                                                                                           |
|  10 |    787.522638 |    230.647273 | Steven Traver                                                                                                                                                                        |
|  11 |    800.427754 |    155.616462 | Sarah Werning                                                                                                                                                                        |
|  12 |    707.035993 |    114.445648 | Steven Traver                                                                                                                                                                        |
|  13 |    140.377457 |    263.180369 | Beth Reinke                                                                                                                                                                          |
|  14 |    658.813289 |    262.974336 | Margot Michaud                                                                                                                                                                       |
|  15 |    512.998582 |    626.953817 | Jagged Fang Designs                                                                                                                                                                  |
|  16 |    397.916281 |    428.370815 | Collin Gross                                                                                                                                                                         |
|  17 |    525.465312 |    465.149735 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
|  18 |    560.385482 |    344.435882 | André Karwath (vectorized by T. Michael Keesey)                                                                                                                                      |
|  19 |    333.885208 |    189.312692 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                                                 |
|  20 |    377.420228 |    586.423009 | Chase Brownstein                                                                                                                                                                     |
|  21 |    454.633077 |     88.192554 | Xavier Giroux-Bougard                                                                                                                                                                |
|  22 |    669.470247 |    697.717678 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                                             |
|  23 |    182.295474 |    660.199137 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  24 |    441.399543 |    235.437036 | Lily Hughes                                                                                                                                                                          |
|  25 |     69.805124 |    710.332017 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
|  26 |    965.733578 |    218.356663 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
|  27 |    588.217944 |    166.723009 | Matt Crook                                                                                                                                                                           |
|  28 |    870.089810 |     29.180496 | Shyamal                                                                                                                                                                              |
|  29 |     82.163427 |    108.950755 | NA                                                                                                                                                                                   |
|  30 |    688.373007 |    479.686693 | Scott Hartman                                                                                                                                                                        |
|  31 |    577.663695 |     74.671238 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
|  32 |    730.326057 |    387.246696 | Ferran Sayol                                                                                                                                                                         |
|  33 |    222.005027 |    475.985494 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  34 |    250.129607 |    562.527941 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                                             |
|  35 |    259.608986 |    231.801412 | Armin Reindl                                                                                                                                                                         |
|  36 |    178.715575 |    735.182333 | Matt Crook                                                                                                                                                                           |
|  37 |    392.727579 |    675.319758 | Ferran Sayol                                                                                                                                                                         |
|  38 |    208.711789 |    129.360048 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
|  39 |     99.491456 |    381.127085 | Anthony Caravaggi                                                                                                                                                                    |
|  40 |    498.340666 |    736.644818 | Lukasiniho                                                                                                                                                                           |
|  41 |    558.416686 |    592.023712 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                                  |
|  42 |    273.313684 |    523.567882 | Scott Hartman                                                                                                                                                                        |
|  43 |    726.312503 |    331.663319 | Scott Hartman                                                                                                                                                                        |
|  44 |    449.703069 |    489.010640 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  45 |    362.557117 |    377.240961 | Chris huh                                                                                                                                                                            |
|  46 |    925.199811 |    124.822109 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                                           |
|  47 |    641.415714 |    515.463600 | NA                                                                                                                                                                                   |
|  48 |    882.386169 |     89.686427 | Andrew A. Farke                                                                                                                                                                      |
|  49 |    943.403131 |    771.142500 | Ferran Sayol                                                                                                                                                                         |
|  50 |    656.711599 |    187.343510 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  51 |    510.623082 |    170.367677 | Ingo Braasch                                                                                                                                                                         |
|  52 |    831.932929 |    313.925199 | Felix Vaux                                                                                                                                                                           |
|  53 |     78.287699 |    283.112630 | Steven Traver                                                                                                                                                                        |
|  54 |    105.280547 |    611.475029 | Emily Jane McTavish                                                                                                                                                                  |
|  55 |    265.411666 |    731.613933 | Christoph Schomburg                                                                                                                                                                  |
|  56 |    327.427584 |     78.909164 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
|  57 |    311.867250 |     32.552606 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  58 |    417.389584 |    526.971729 | NA                                                                                                                                                                                   |
|  59 |    928.429132 |    295.175159 | Scott Hartman                                                                                                                                                                        |
|  60 |    648.701473 |    761.379701 | Anna Willoughby                                                                                                                                                                      |
|  61 |    315.905704 |    648.113505 | Rebecca Groom                                                                                                                                                                        |
|  62 |    487.416538 |    559.408453 | NA                                                                                                                                                                                   |
|  63 |    492.885803 |    372.261291 | Yan Wong                                                                                                                                                                             |
|  64 |    403.575847 |    144.323600 | Scott Hartman                                                                                                                                                                        |
|  65 |    737.064344 |    584.182775 | Birgit Lang, based on a photo by D. Sikes                                                                                                                                            |
|  66 |    283.341549 |    767.836036 | Tasman Dixon                                                                                                                                                                         |
|  67 |    640.743129 |    458.968712 | Jagged Fang Designs                                                                                                                                                                  |
|  68 |     90.831220 |     26.560416 | Jaime Headden                                                                                                                                                                        |
|  69 |    674.295769 |     41.154283 | Steven Traver                                                                                                                                                                        |
|  70 |    771.741674 |    758.313216 | Chuanixn Yu                                                                                                                                                                          |
|  71 |    959.119771 |    350.706068 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                                          |
|  72 |    232.592292 |    354.187435 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                                          |
|  73 |    694.977984 |    426.703189 | Emily Willoughby                                                                                                                                                                     |
|  74 |    148.705665 |    457.783943 | NA                                                                                                                                                                                   |
|  75 |    673.931123 |    643.313126 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
|  76 |     60.884140 |    605.816564 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                                        |
|  77 |    446.863074 |     31.496123 | Chris huh                                                                                                                                                                            |
|  78 |    776.553284 |     72.754643 | Gareth Monger                                                                                                                                                                        |
|  79 |    567.755378 |     23.585288 | Scott Hartman                                                                                                                                                                        |
|  80 |    926.612510 |    490.732904 | Margot Michaud                                                                                                                                                                       |
|  81 |    977.559552 |    449.665345 | NA                                                                                                                                                                                   |
|  82 |    575.224616 |    559.515299 | NA                                                                                                                                                                                   |
|  83 |    559.465245 |    109.082223 | Zimices                                                                                                                                                                              |
|  84 |    687.971120 |     11.399802 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                                     |
|  85 |    639.410342 |    608.933616 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
|  86 |    705.542312 |    788.815935 | FunkMonk                                                                                                                                                                             |
|  87 |    800.068413 |    578.360618 | Mathew Wedel                                                                                                                                                                         |
|  88 |    427.996743 |    768.468518 | Matt Crook                                                                                                                                                                           |
|  89 |     65.210394 |    783.479536 | NA                                                                                                                                                                                   |
|  90 |    751.515622 |    245.140064 | Steven Traver                                                                                                                                                                        |
|  91 |    348.039979 |    474.726715 | Ignacio Contreras                                                                                                                                                                    |
|  92 |    942.551438 |    143.199816 | Esme Ashe-Jepson                                                                                                                                                                     |
|  93 |     87.502560 |    229.614475 | Zimices                                                                                                                                                                              |
|  94 |    654.893348 |    365.071560 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                                            |
|  95 |    501.813051 |    468.361134 | Matt Crook                                                                                                                                                                           |
|  96 |    299.188785 |    470.850407 | Zimices                                                                                                                                                                              |
|  97 |    612.722231 |    229.139861 | Roberto Díaz Sibaja                                                                                                                                                                  |
|  98 |    103.189348 |     39.858496 | Matt Crook                                                                                                                                                                           |
|  99 |    441.120967 |    165.672036 | NA                                                                                                                                                                                   |
| 100 |     35.483172 |    203.259663 | ArtFavor & annaleeblysse                                                                                                                                                             |
| 101 |    375.670807 |    633.689168 | Scott Hartman, modified by T. Michael Keesey                                                                                                                                         |
| 102 |    456.992595 |    682.427261 | T. Michael Keesey                                                                                                                                                                    |
| 103 |   1005.902936 |    401.068334 | Mattia Menchetti                                                                                                                                                                     |
| 104 |    620.363472 |    317.108824 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 105 |    759.881450 |    270.102449 | Mattia Menchetti / Yan Wong                                                                                                                                                          |
| 106 |    528.247126 |    643.062544 | Zimices                                                                                                                                                                              |
| 107 |    982.939601 |    721.883893 | Shyamal                                                                                                                                                                              |
| 108 |    998.419708 |    147.520536 | Zimices, based in Mauricio Antón skeletal                                                                                                                                            |
| 109 |    642.014645 |    589.481872 | Jagged Fang Designs                                                                                                                                                                  |
| 110 |     99.271253 |    772.327492 | Matt Crook                                                                                                                                                                           |
| 111 |    754.360268 |    442.787966 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                                        |
| 112 |    295.711261 |    445.374625 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                                     |
| 113 |    234.365120 |    589.758479 | Steven Traver                                                                                                                                                                        |
| 114 |    355.691235 |     83.950821 | Steven Traver                                                                                                                                                                        |
| 115 |    278.411943 |     99.794443 | Gareth Monger                                                                                                                                                                        |
| 116 |    328.149381 |    549.595670 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 117 |    556.650204 |    484.151490 | Scott Hartman                                                                                                                                                                        |
| 118 |     87.555376 |    671.590751 | Markus A. Grohme                                                                                                                                                                     |
| 119 |    901.517668 |    248.601204 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 120 |    749.250050 |    514.373746 | Gareth Monger                                                                                                                                                                        |
| 121 |    998.933735 |    427.267316 | Steven Traver                                                                                                                                                                        |
| 122 |    450.279604 |    763.675071 | Frank Förster                                                                                                                                                                        |
| 123 |    434.528760 |    544.847995 | Yan Wong                                                                                                                                                                             |
| 124 |   1003.229058 |     82.003609 | Christoph Schomburg                                                                                                                                                                  |
| 125 |     77.713130 |     61.191920 | Zimices                                                                                                                                                                              |
| 126 |    441.677012 |    213.584474 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
| 127 |    254.274118 |    684.890818 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 128 |    948.261539 |    790.011646 | Aline M. Ghilardi                                                                                                                                                                    |
| 129 |    597.254441 |    372.687333 | annaleeblysse                                                                                                                                                                        |
| 130 |    815.636148 |    276.722721 | Chris Jennings (Risiatto)                                                                                                                                                            |
| 131 |    260.146715 |    640.753714 | Zimices                                                                                                                                                                              |
| 132 |    972.476322 |    533.295648 | David Orr                                                                                                                                                                            |
| 133 |     26.841286 |    381.889311 | NA                                                                                                                                                                                   |
| 134 |   1012.407791 |    696.726361 | Dmitry Bogdanov                                                                                                                                                                      |
| 135 |    144.899466 |    703.290975 | Sebastian Stabinger                                                                                                                                                                  |
| 136 |    182.069199 |    781.904672 | Robert Gay                                                                                                                                                                           |
| 137 |    915.360070 |     74.438580 | Michael Scroggie                                                                                                                                                                     |
| 138 |    987.083389 |    348.460245 | Zimices                                                                                                                                                                              |
| 139 |    133.587718 |    286.256554 | Kai R. Caspar                                                                                                                                                                        |
| 140 |     14.350411 |    356.553689 | Ferran Sayol                                                                                                                                                                         |
| 141 |    939.948036 |    325.099628 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                                     |
| 142 |    278.410681 |    597.148144 | Zimices                                                                                                                                                                              |
| 143 |    163.369072 |    360.533558 | Tauana J. Cunha                                                                                                                                                                      |
| 144 |   1009.550378 |    564.929082 | Chris huh                                                                                                                                                                            |
| 145 |    587.212506 |    410.811078 | Maija Karala                                                                                                                                                                         |
| 146 |    423.891359 |    561.081348 | Ferran Sayol                                                                                                                                                                         |
| 147 |     25.309521 |    183.213465 | Gareth Monger                                                                                                                                                                        |
| 148 |    736.804947 |    213.463757 | Zimices                                                                                                                                                                              |
| 149 |    754.332987 |    363.534716 | NA                                                                                                                                                                                   |
| 150 |    177.891660 |    347.806034 | Lauren Sumner-Rooney                                                                                                                                                                 |
| 151 |    611.882535 |    641.094302 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                               |
| 152 |    568.210179 |    772.599904 | Agnello Picorelli                                                                                                                                                                    |
| 153 |    667.364358 |    777.224663 | Margot Michaud                                                                                                                                                                       |
| 154 |    697.009630 |    689.627313 | Jagged Fang Designs                                                                                                                                                                  |
| 155 |    212.171808 |    268.345785 | Ville-Veikko Sinkkonen                                                                                                                                                               |
| 156 |     17.394569 |     34.991100 | Scott Reid                                                                                                                                                                           |
| 157 |    850.651031 |    769.832620 | Gareth Monger                                                                                                                                                                        |
| 158 |    857.649290 |    209.067891 | Karina Garcia                                                                                                                                                                        |
| 159 |    408.992562 |    120.687828 | Markus A. Grohme                                                                                                                                                                     |
| 160 |    981.297464 |     94.504264 | NA                                                                                                                                                                                   |
| 161 |    475.744664 |    369.933049 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                                                |
| 162 |    361.500653 |    773.429972 | Gareth Monger                                                                                                                                                                        |
| 163 |    577.663449 |    239.909227 | Matt Crook                                                                                                                                                                           |
| 164 |    687.450454 |    584.536737 | Zimices                                                                                                                                                                              |
| 165 |     91.843649 |    168.250333 | Scott Hartman                                                                                                                                                                        |
| 166 |    406.324392 |    457.750495 | Zimices                                                                                                                                                                              |
| 167 |    897.732206 |    183.631286 | Robert Gay                                                                                                                                                                           |
| 168 |    795.521238 |    601.757050 | Matt Crook                                                                                                                                                                           |
| 169 |    411.200673 |    581.489493 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
| 170 |    721.282392 |    261.967794 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 171 |    555.418665 |    539.792289 | Javier Luque                                                                                                                                                                         |
| 172 |    239.282752 |    479.555622 | Maija Karala                                                                                                                                                                         |
| 173 |    709.811940 |    440.119448 | Agnello Picorelli                                                                                                                                                                    |
| 174 |    227.081430 |     91.331821 | Steven Traver                                                                                                                                                                        |
| 175 |    552.935640 |    404.019033 | Rebecca Groom                                                                                                                                                                        |
| 176 |    623.364130 |     74.590997 | Yan Wong                                                                                                                                                                             |
| 177 |    840.911625 |    419.929725 | Zimices                                                                                                                                                                              |
| 178 |    322.403293 |    114.047500 | Steven Traver                                                                                                                                                                        |
| 179 |    646.335083 |    311.195101 | Margot Michaud                                                                                                                                                                       |
| 180 |    718.924902 |    513.017387 | Matt Crook                                                                                                                                                                           |
| 181 |    295.413907 |    107.542094 | Matt Crook                                                                                                                                                                           |
| 182 |    716.042166 |    371.204415 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 183 |    463.660714 |    431.211054 | B. Duygu Özpolat                                                                                                                                                                     |
| 184 |     47.141120 |    181.796634 | Gareth Monger                                                                                                                                                                        |
| 185 |    588.468041 |    740.105064 | Renato de Carvalho Ferreira                                                                                                                                                          |
| 186 |    445.080432 |    603.732074 | Matt Crook                                                                                                                                                                           |
| 187 |    504.608422 |    636.103786 | Matt Crook                                                                                                                                                                           |
| 188 |    751.897209 |    627.489071 | NA                                                                                                                                                                                   |
| 189 |    985.103988 |     26.807568 | xgirouxb                                                                                                                                                                             |
| 190 |    495.606897 |     55.849899 | Robert Gay                                                                                                                                                                           |
| 191 |    186.431298 |    241.376103 | Scott Hartman                                                                                                                                                                        |
| 192 |    925.760494 |    385.431727 | Jimmy Bernot                                                                                                                                                                         |
| 193 |    674.698536 |    341.299113 | Emily Willoughby                                                                                                                                                                     |
| 194 |    697.185813 |    744.017543 | Markus A. Grohme                                                                                                                                                                     |
| 195 |    351.011109 |    393.050028 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 196 |    972.429970 |    744.296454 | Rebecca Groom                                                                                                                                                                        |
| 197 |    161.042129 |    618.755703 | Francesca Belem Lopes Palmeira                                                                                                                                                       |
| 198 |    127.765118 |     91.245398 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                               |
| 199 |    986.007786 |    270.948659 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 200 |    497.286245 |     64.916425 | Steven Traver                                                                                                                                                                        |
| 201 |    746.863632 |     58.429546 | Iain Reid                                                                                                                                                                            |
| 202 |    113.202673 |    657.108596 | Michael Scroggie                                                                                                                                                                     |
| 203 |    687.970352 |    618.404871 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                                             |
| 204 |    607.129415 |    610.604162 | Matt Crook                                                                                                                                                                           |
| 205 |    124.389121 |    107.327191 | Scott Hartman                                                                                                                                                                        |
| 206 |    445.711103 |    380.208333 | Donovan Reginald Rosevear (vectorized by T. Michael Keesey)                                                                                                                          |
| 207 |    193.852211 |    230.307102 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 208 |     40.865214 |    334.515431 | Michael Scroggie                                                                                                                                                                     |
| 209 |    808.792952 |    770.864682 | Chris huh                                                                                                                                                                            |
| 210 |    862.207546 |    283.401649 | Anthony Caravaggi                                                                                                                                                                    |
| 211 |    183.886659 |    427.694448 | Matt Crook                                                                                                                                                                           |
| 212 |    835.314069 |    755.691998 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 213 |    572.365182 |    424.457360 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                                 |
| 214 |   1001.524818 |    540.163417 | Beth Reinke                                                                                                                                                                          |
| 215 |    139.634163 |     41.658273 | Griensteidl and T. Michael Keesey                                                                                                                                                    |
| 216 |    599.241478 |    596.842041 | Bryan Carstens                                                                                                                                                                       |
| 217 |     41.329573 |    757.665997 | Tracy A. Heath                                                                                                                                                                       |
| 218 |    124.685778 |    790.483817 | Matthew E. Clapham                                                                                                                                                                   |
| 219 |    923.217000 |    407.696334 | Renata F. Martins                                                                                                                                                                    |
| 220 |    940.831102 |    739.513136 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 221 |    366.199856 |    118.470923 | Kailah Thorn & Ben King                                                                                                                                                              |
| 222 |    124.404917 |    438.723078 | Michelle Site                                                                                                                                                                        |
| 223 |    664.883601 |     12.036725 | NA                                                                                                                                                                                   |
| 224 |    430.211567 |    357.793151 | Margot Michaud                                                                                                                                                                       |
| 225 |    334.846117 |    301.583660 | NA                                                                                                                                                                                   |
| 226 |    286.483902 |    492.200561 | Duane Raver/USFWS                                                                                                                                                                    |
| 227 |    357.479046 |    502.600450 | Matt Crook                                                                                                                                                                           |
| 228 |    388.556870 |     48.856207 | Julio Garza                                                                                                                                                                          |
| 229 |     74.241135 |    640.804864 | Chris huh                                                                                                                                                                            |
| 230 |    732.851176 |    664.975670 | Chris huh                                                                                                                                                                            |
| 231 |    544.975002 |    556.328114 | Yan Wong                                                                                                                                                                             |
| 232 |    464.924477 |    782.787915 | Iain Reid                                                                                                                                                                            |
| 233 |    425.033877 |    731.123687 | Renata F. Martins                                                                                                                                                                    |
| 234 |    739.482083 |    358.482214 | Mariana Ruiz Villarreal                                                                                                                                                              |
| 235 |   1000.309501 |    214.176144 | Zimices                                                                                                                                                                              |
| 236 |    908.196125 |    468.492852 | Margot Michaud                                                                                                                                                                       |
| 237 |    939.573766 |     51.857355 | Margot Michaud                                                                                                                                                                       |
| 238 |    765.823148 |    305.047673 | JCGiron                                                                                                                                                                              |
| 239 |    732.136721 |    168.625057 | Ferran Sayol                                                                                                                                                                         |
| 240 |    580.066565 |    217.997854 | L. Shyamal                                                                                                                                                                           |
| 241 |    983.748068 |    586.944870 | NA                                                                                                                                                                                   |
| 242 |   1010.937718 |    360.938505 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 243 |    124.702919 |    163.940751 | NA                                                                                                                                                                                   |
| 244 |    523.362646 |    252.005089 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                                        |
| 245 |    719.188067 |     58.860960 | NA                                                                                                                                                                                   |
| 246 |    261.082045 |     12.646676 | Smokeybjb                                                                                                                                                                            |
| 247 |    777.220445 |    537.614437 | Matt Martyniuk                                                                                                                                                                       |
| 248 |    505.238225 |    292.802107 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                               |
| 249 |    360.492493 |    535.139167 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 250 |    586.178712 |    119.959839 | Matt Crook                                                                                                                                                                           |
| 251 |    314.843902 |    264.294145 | Abraão Leite                                                                                                                                                                         |
| 252 |    572.259035 |    317.777388 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                     |
| 253 |    560.859752 |    282.165645 | Harold N Eyster                                                                                                                                                                      |
| 254 |    509.864745 |    210.075948 | Michelle Site                                                                                                                                                                        |
| 255 |    294.429328 |     95.368098 | Zimices                                                                                                                                                                              |
| 256 |    778.797780 |     36.729305 | Jagged Fang Designs                                                                                                                                                                  |
| 257 |   1008.234330 |    602.316276 | NA                                                                                                                                                                                   |
| 258 |     20.381838 |     90.902071 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 259 |    149.454086 |    340.435499 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 260 |    655.962669 |    777.167728 | Armin Reindl                                                                                                                                                                         |
| 261 |    605.378301 |    108.663287 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                               |
| 262 |    508.613445 |    778.046013 | Shyamal                                                                                                                                                                              |
| 263 |    828.042840 |    715.725663 | Ferran Sayol                                                                                                                                                                         |
| 264 |     45.557255 |    352.017379 | Benchill                                                                                                                                                                             |
| 265 |    386.204226 |    771.872532 | L. Shyamal                                                                                                                                                                           |
| 266 |    412.606320 |    177.574637 | Ferran Sayol                                                                                                                                                                         |
| 267 |    689.379974 |    673.718588 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                                              |
| 268 |    602.224060 |     99.986423 | Karla Martinez                                                                                                                                                                       |
| 269 |    636.970796 |    721.211579 | Gareth Monger                                                                                                                                                                        |
| 270 |     15.194466 |    757.126569 | Matt Crook                                                                                                                                                                           |
| 271 |    109.187117 |    610.412719 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 272 |   1004.429449 |    664.828608 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 273 |    173.756135 |    568.478656 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                                              |
| 274 |    549.518552 |    642.385005 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 275 |    381.351296 |     96.375612 | Margot Michaud                                                                                                                                                                       |
| 276 |   1014.338732 |     70.770730 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 277 |    318.222755 |    360.236581 | NA                                                                                                                                                                                   |
| 278 |    560.182654 |    500.297567 | Markus A. Grohme                                                                                                                                                                     |
| 279 |    497.456701 |    194.898887 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 280 |    307.863730 |     85.516240 | Zimices                                                                                                                                                                              |
| 281 |   1012.036822 |    637.169134 | Lafage                                                                                                                                                                               |
| 282 |    688.981139 |    502.312386 | Neil Kelley                                                                                                                                                                          |
| 283 |    163.819936 |    437.942212 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 284 |    951.184207 |    724.768529 | Matt Crook                                                                                                                                                                           |
| 285 |    865.302669 |    775.573485 | Chris huh                                                                                                                                                                            |
| 286 |    954.543560 |    117.454633 | Ingo Braasch                                                                                                                                                                         |
| 287 |    918.726540 |     52.444413 | Chris huh                                                                                                                                                                            |
| 288 |    849.897174 |    740.416983 | Esme Ashe-Jepson                                                                                                                                                                     |
| 289 |    180.116237 |    616.660150 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                                           |
| 290 |    221.839194 |    166.208846 | Zimices / Julián Bayona                                                                                                                                                              |
| 291 |    111.225261 |    400.554342 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 292 |    218.122216 |    487.110180 | Ludwik Gasiorowski                                                                                                                                                                   |
| 293 |    599.050996 |    211.617984 | Jagged Fang Designs                                                                                                                                                                  |
| 294 |    302.321117 |    774.278521 | Zimices                                                                                                                                                                              |
| 295 |    956.699169 |    135.215332 | Chris huh                                                                                                                                                                            |
| 296 |    517.160076 |    314.230398 | Chris huh                                                                                                                                                                            |
| 297 |    334.577002 |    293.132183 | Anthony Caravaggi                                                                                                                                                                    |
| 298 |    302.898281 |    139.123916 | xgirouxb                                                                                                                                                                             |
| 299 |    707.063667 |    673.934616 | Jagged Fang Designs                                                                                                                                                                  |
| 300 |     37.738249 |    650.147229 | Margot Michaud                                                                                                                                                                       |
| 301 |    374.913824 |    792.167817 | Matt Crook                                                                                                                                                                           |
| 302 |    559.051472 |    700.433203 | Matt Crook                                                                                                                                                                           |
| 303 |    184.968962 |     69.798623 | Beth Reinke                                                                                                                                                                          |
| 304 |    668.228362 |    222.779853 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                                    |
| 305 |      8.567475 |    441.552768 | Mattia Menchetti                                                                                                                                                                     |
| 306 |    985.538169 |    514.293916 | Chris huh                                                                                                                                                                            |
| 307 |    393.407306 |     19.697710 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 308 |    608.186397 |      3.772954 | Chuanixn Yu                                                                                                                                                                          |
| 309 |    384.476057 |    454.281812 | Abraão B. Leite                                                                                                                                                                      |
| 310 |    795.945357 |      5.303186 | Smokeybjb                                                                                                                                                                            |
| 311 |    449.165383 |    408.968482 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                                              |
| 312 |    204.048060 |    758.808513 | Markus A. Grohme                                                                                                                                                                     |
| 313 |    842.659310 |    728.688948 | Zimices                                                                                                                                                                              |
| 314 |    941.499402 |    549.482202 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
| 315 |    912.439014 |    357.607620 | Zimices                                                                                                                                                                              |
| 316 |    904.979203 |    740.613129 | Matt Crook                                                                                                                                                                           |
| 317 |    625.420154 |    539.130613 | Matt Crook                                                                                                                                                                           |
| 318 |    216.941012 |    248.585726 | T. Michael Keesey                                                                                                                                                                    |
| 319 |     49.588168 |      6.724030 | Louis Ranjard                                                                                                                                                                        |
| 320 |    555.202520 |    386.928261 | Chris huh                                                                                                                                                                            |
| 321 |    494.310719 |    135.797031 | Markus A. Grohme                                                                                                                                                                     |
| 322 |    938.394022 |    746.565215 | Gareth Monger                                                                                                                                                                        |
| 323 |    565.160394 |    652.279490 | Caleb Brown                                                                                                                                                                          |
| 324 |    641.568502 |    221.240828 | Caleb M. Brown                                                                                                                                                                       |
| 325 |    488.811521 |     15.677812 | NA                                                                                                                                                                                   |
| 326 |    849.053499 |    297.833768 | NA                                                                                                                                                                                   |
| 327 |    193.530046 |    774.864988 | Sarah Werning                                                                                                                                                                        |
| 328 |    230.504215 |    149.085053 | Henry Lydecker                                                                                                                                                                       |
| 329 |    774.815767 |    282.580201 | Markus A. Grohme                                                                                                                                                                     |
| 330 |    726.787977 |    227.762866 | FunkMonk                                                                                                                                                                             |
| 331 |    408.413638 |    500.502521 | Christoph Schomburg                                                                                                                                                                  |
| 332 |    950.848721 |    381.012618 | Zimices                                                                                                                                                                              |
| 333 |    972.008874 |    367.816993 | Emily Willoughby                                                                                                                                                                     |
| 334 |    277.563609 |    545.079703 | Scott Hartman                                                                                                                                                                        |
| 335 |    447.040247 |    252.491614 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 336 |    605.267190 |    487.399428 | Kamil S. Jaron                                                                                                                                                                       |
| 337 |    913.854706 |    198.054381 | T. Michael Keesey                                                                                                                                                                    |
| 338 |    400.402149 |    769.309436 | Sarah Werning                                                                                                                                                                        |
| 339 |    796.316439 |    415.166218 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 340 |    205.719591 |    284.651042 | Zimices                                                                                                                                                                              |
| 341 |    955.782186 |    532.319346 | Matt Dempsey                                                                                                                                                                         |
| 342 |    629.649392 |    790.903155 | Harold N Eyster                                                                                                                                                                      |
| 343 |    566.868236 |    391.875351 | Cesar Julian                                                                                                                                                                         |
| 344 |   1016.194009 |    681.556885 | Matt Crook                                                                                                                                                                           |
| 345 |    608.867306 |    629.717990 | SecretJellyMan - from Mason McNair                                                                                                                                                   |
| 346 |     51.018604 |    402.758417 | Melissa Broussard                                                                                                                                                                    |
| 347 |    662.390749 |    400.131801 | Rachel Shoop                                                                                                                                                                         |
| 348 |    609.749453 |     22.917747 | Matt Crook                                                                                                                                                                           |
| 349 |     16.729667 |    407.695985 | Rebecca Groom                                                                                                                                                                        |
| 350 |    814.850919 |     56.290974 | Jagged Fang Designs                                                                                                                                                                  |
| 351 |    763.344315 |    535.021319 | Steven Traver                                                                                                                                                                        |
| 352 |    626.961466 |    660.370466 | Gareth Monger                                                                                                                                                                        |
| 353 |    151.267149 |    240.047422 | Zimices                                                                                                                                                                              |
| 354 |    841.113585 |    716.867725 | Margot Michaud                                                                                                                                                                       |
| 355 |    381.488372 |    204.521512 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 356 |    153.252608 |    511.854431 | T. Michael Keesey                                                                                                                                                                    |
| 357 |    183.868332 |    157.082933 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 358 |    261.181226 |    286.861053 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                                  |
| 359 |     15.810423 |    114.095580 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 360 |    414.938265 |    792.284676 | NA                                                                                                                                                                                   |
| 361 |    792.014265 |    568.187959 | Zimices                                                                                                                                                                              |
| 362 |    393.572181 |    727.034537 | NA                                                                                                                                                                                   |
| 363 |    276.560336 |    142.147192 | Lafage                                                                                                                                                                               |
| 364 |    536.900261 |    495.341111 | Gareth Monger                                                                                                                                                                        |
| 365 |    976.915857 |    328.938948 | Madeleine Price Ball                                                                                                                                                                 |
| 366 |    500.059025 |    787.976823 | Griensteidl and T. Michael Keesey                                                                                                                                                    |
| 367 |    213.220036 |    369.610423 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                                            |
| 368 |    258.380543 |    742.061196 | Sarah Werning                                                                                                                                                                        |
| 369 |    165.860393 |    539.851755 | NA                                                                                                                                                                                   |
| 370 |    709.173263 |    544.198524 | NA                                                                                                                                                                                   |
| 371 |    664.156581 |    344.834728 | Gareth Monger                                                                                                                                                                        |
| 372 |    720.581683 |    642.946289 | Cagri Cevrim                                                                                                                                                                         |
| 373 |   1012.272704 |    330.524354 | Cesar Julian                                                                                                                                                                         |
| 374 |    349.464109 |     22.438893 | NA                                                                                                                                                                                   |
| 375 |    129.552775 |    687.434387 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                                 |
| 376 |    775.854735 |    516.363427 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 377 |    813.401967 |    256.306706 | Maxime Dahirel                                                                                                                                                                       |
| 378 |    272.383860 |    694.788057 | Luis Cunha                                                                                                                                                                           |
| 379 |    466.247195 |    185.181306 | Steven Coombs                                                                                                                                                                        |
| 380 |    576.100522 |    152.343700 | Emily Willoughby                                                                                                                                                                     |
| 381 |   1009.009513 |     94.208220 | NA                                                                                                                                                                                   |
| 382 |    954.103879 |    417.600286 | Christoph Schomburg                                                                                                                                                                  |
| 383 |    987.844034 |    734.015944 | Gareth Monger                                                                                                                                                                        |
| 384 |    565.101624 |    643.455390 | Emily Willoughby                                                                                                                                                                     |
| 385 |   1013.702131 |    244.296010 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                                      |
| 386 |    566.142710 |    159.910437 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 387 |    471.769705 |     57.522374 | Zimices                                                                                                                                                                              |
| 388 |    589.585873 |    540.949670 | NA                                                                                                                                                                                   |
| 389 |    203.073761 |    747.511770 | Matt Crook                                                                                                                                                                           |
| 390 |    106.809930 |    273.473590 | Gareth Monger                                                                                                                                                                        |
| 391 |    242.827322 |    384.534196 | Zimices                                                                                                                                                                              |
| 392 |    445.421489 |    195.354576 | Zimices                                                                                                                                                                              |
| 393 |    187.900601 |    755.061264 | Margot Michaud                                                                                                                                                                       |
| 394 |     44.111590 |    434.235605 | Ferran Sayol                                                                                                                                                                         |
| 395 |    897.523196 |    112.693312 | Birgit Lang                                                                                                                                                                          |
| 396 |    460.857141 |      7.220501 | Xavier Giroux-Bougard                                                                                                                                                                |
| 397 |    374.977778 |     23.747597 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 398 |    436.549368 |    571.407976 | John Gould (vectorized by T. Michael Keesey)                                                                                                                                         |
| 399 |     59.350863 |    660.089517 | Gareth Monger                                                                                                                                                                        |
| 400 |    165.217912 |    225.204604 | Birgit Lang                                                                                                                                                                          |
| 401 |    248.464381 |    452.943066 | Ferran Sayol                                                                                                                                                                         |
| 402 |    587.559221 |    352.262920 | Beth Reinke                                                                                                                                                                          |
| 403 |   1005.002167 |    574.883245 | Andrew A. Farke                                                                                                                                                                      |
| 404 |    693.562259 |    651.458740 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 405 |    308.858677 |    377.475654 | Ignacio Contreras                                                                                                                                                                    |
| 406 |   1000.851396 |    333.159426 | Florian Pfaff                                                                                                                                                                        |
| 407 |    425.395461 |    261.602520 | Trond R. Oskars                                                                                                                                                                      |
| 408 |     69.566113 |     44.924794 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                                          |
| 409 |     68.174041 |     50.129162 | Jagged Fang Designs                                                                                                                                                                  |
| 410 |    533.107745 |    591.074250 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 411 |    145.871834 |     63.703678 | Zimices                                                                                                                                                                              |
| 412 |    932.757080 |    529.837547 | Matt Crook                                                                                                                                                                           |
| 413 |    302.619334 |    529.598033 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                                        |
| 414 |    275.660094 |    432.893060 | CNZdenek                                                                                                                                                                             |
| 415 |    577.938018 |    454.839987 | Javier Luque                                                                                                                                                                         |
| 416 |    765.905693 |    161.941139 | Margot Michaud                                                                                                                                                                       |
| 417 |     12.348425 |    638.984515 | T. Michael Keesey                                                                                                                                                                    |
| 418 |   1007.791862 |    276.816785 | Tasman Dixon                                                                                                                                                                         |
| 419 |    629.630840 |    393.136584 | NA                                                                                                                                                                                   |
| 420 |   1009.741919 |     12.466451 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 421 |    312.033897 |    480.914354 | Steven Traver                                                                                                                                                                        |
| 422 |    198.119110 |    182.777331 | Harold N Eyster                                                                                                                                                                      |
| 423 |    991.282076 |    322.722433 | Sarah Werning                                                                                                                                                                        |
| 424 |    532.100621 |    144.045694 | Ignacio Contreras                                                                                                                                                                    |
| 425 |    379.914316 |    472.020829 | Milton Tan                                                                                                                                                                           |
| 426 |    787.566849 |    493.201914 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 427 |    484.225170 |    399.689531 | Matt Dempsey                                                                                                                                                                         |
| 428 |    948.927095 |    318.834665 | Margot Michaud                                                                                                                                                                       |
| 429 |    182.804802 |    531.572576 | NA                                                                                                                                                                                   |
| 430 |    706.968684 |    600.785063 | Chris huh                                                                                                                                                                            |
| 431 |    212.312020 |    186.788645 | Shyamal                                                                                                                                                                              |
| 432 |    307.825635 |    402.551563 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 433 |    825.011697 |    344.060379 | M Kolmann                                                                                                                                                                            |
| 434 |    766.514423 |     49.013946 | Gareth Monger                                                                                                                                                                        |
| 435 |    729.242067 |    615.342279 | Scott Hartman                                                                                                                                                                        |
| 436 |     17.747856 |    774.780845 | Maxime Dahirel                                                                                                                                                                       |
| 437 |   1004.912942 |    675.594682 | Ferran Sayol                                                                                                                                                                         |
| 438 |    415.412769 |    199.983575 | Joanna Wolfe                                                                                                                                                                         |
| 439 |    297.981337 |      6.169199 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 440 |    746.813242 |    504.787891 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                                            |
| 441 |    514.231327 |    555.393214 | Maxime Dahirel                                                                                                                                                                       |
| 442 |    728.158397 |    136.766098 | Michelle Site                                                                                                                                                                        |
| 443 |    859.639852 |    248.082525 | NA                                                                                                                                                                                   |
| 444 |    771.795203 |     85.854610 | Jagged Fang Designs                                                                                                                                                                  |
| 445 |    121.853156 |     40.388198 | T. Michael Keesey                                                                                                                                                                    |
| 446 |    182.369866 |    182.060416 | Matt Crook                                                                                                                                                                           |
| 447 |    742.052103 |    523.470647 | T. Michael Keesey                                                                                                                                                                    |
| 448 |     19.100010 |    635.960092 | Gareth Monger                                                                                                                                                                        |
| 449 |    296.426649 |    717.265065 | Andrew A. Farke                                                                                                                                                                      |
| 450 |    860.439716 |    170.585822 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                                    |
| 451 |    982.936444 |    547.488917 | Tracy A. Heath                                                                                                                                                                       |
| 452 |    715.618245 |    503.817007 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 453 |    919.055204 |    136.277518 | Zimices                                                                                                                                                                              |
| 454 |    819.896308 |    599.859831 | Scott Hartman                                                                                                                                                                        |
| 455 |    115.671933 |     10.603250 | Scott Hartman                                                                                                                                                                        |
| 456 |    953.525398 |    125.748802 | NA                                                                                                                                                                                   |
| 457 |    370.554820 |    453.855593 | NA                                                                                                                                                                                   |
| 458 |    891.884192 |    200.820997 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 459 |    764.613505 |    709.592658 | Melissa Broussard                                                                                                                                                                    |
| 460 |    406.656123 |    113.197564 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 461 |    189.102160 |     86.014284 | Nobu Tamura                                                                                                                                                                          |
| 462 |    123.779637 |    497.988516 | T. Michael Keesey                                                                                                                                                                    |
| 463 |    892.026850 |    733.067741 | Zimices                                                                                                                                                                              |
| 464 |     25.231470 |    106.707174 | Michele M Tobias                                                                                                                                                                     |
| 465 |    239.764661 |    614.404179 | Jaime Headden, modified by T. Michael Keesey                                                                                                                                         |
| 466 |    511.482546 |    591.258509 | Armin Reindl                                                                                                                                                                         |
| 467 |    460.814209 |    402.086246 | Smokeybjb                                                                                                                                                                            |
| 468 |    678.919037 |    456.329734 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                                    |
| 469 |    471.477630 |    665.088103 | Margot Michaud                                                                                                                                                                       |
| 470 |    713.468174 |     26.877273 | Cristina Guijarro                                                                                                                                                                    |
| 471 |    208.389027 |    547.549863 | Markus A. Grohme                                                                                                                                                                     |
| 472 |    800.304350 |     56.899400 | Crystal Maier                                                                                                                                                                        |
| 473 |    493.027445 |    447.076716 | Steven Traver                                                                                                                                                                        |
| 474 |    718.874896 |    461.683971 | NA                                                                                                                                                                                   |
| 475 |    962.936359 |    148.948313 | Ferran Sayol                                                                                                                                                                         |
| 476 |    172.178336 |    551.982932 | James Neenan                                                                                                                                                                         |
| 477 |    636.372324 |    383.309270 | Gareth Monger                                                                                                                                                                        |
| 478 |    829.960488 |    361.802480 | Maxime Dahirel                                                                                                                                                                       |
| 479 |    141.527283 |     83.372265 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 480 |    791.416020 |    524.496750 | Anthony Caravaggi                                                                                                                                                                    |
| 481 |    221.167380 |     69.739388 | Matt Crook                                                                                                                                                                           |
| 482 |    138.010636 |    104.467718 | Kai R. Caspar                                                                                                                                                                        |
| 483 |    889.761680 |    352.623455 | Michael Scroggie                                                                                                                                                                     |
| 484 |    662.954701 |    299.538582 | NA                                                                                                                                                                                   |
| 485 |    405.839799 |     95.088489 | Maija Karala                                                                                                                                                                         |
| 486 |    828.906353 |    778.967285 | Ferran Sayol                                                                                                                                                                         |
| 487 |    567.550495 |    714.644964 | Dean Schnabel                                                                                                                                                                        |
| 488 |    340.361909 |    461.581148 | (after Spotila 2004)                                                                                                                                                                 |
| 489 |    191.388534 |    586.664677 | Dr. Thomas G. Barnes, USFWS                                                                                                                                                          |
| 490 |    637.232849 |    101.613203 | Richard J. Harris                                                                                                                                                                    |
| 491 |    353.796546 |    778.198055 | Lukasiniho                                                                                                                                                                           |
| 492 |    977.976496 |    490.141745 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 493 |     30.002677 |    627.188634 | Terpsichores                                                                                                                                                                         |
| 494 |    667.666306 |    386.313563 | Juan Carlos Jerí                                                                                                                                                                     |
| 495 |    788.858148 |    378.602409 | Matt Crook                                                                                                                                                                           |
| 496 |    110.245985 |    253.996612 | Scott Hartman                                                                                                                                                                        |
| 497 |    325.837249 |    452.460454 | Zimices                                                                                                                                                                              |
| 498 |    790.614856 |    101.606563 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 499 |    625.478176 |    423.995823 | Dean Schnabel                                                                                                                                                                        |
| 500 |    398.202354 |    175.048086 | NA                                                                                                                                                                                   |
| 501 |    735.875606 |    287.803133 | Markus A. Grohme                                                                                                                                                                     |
| 502 |    718.776223 |    427.861457 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                               |
| 503 |     67.260813 |    176.860954 | Zimices                                                                                                                                                                              |
| 504 |    528.407163 |    789.106841 | Rebecca Groom                                                                                                                                                                        |
| 505 |    315.605091 |    696.557731 | T. Michael Keesey                                                                                                                                                                    |
| 506 |    326.937328 |    562.885552 | Lily Hughes                                                                                                                                                                          |
| 507 |    325.876249 |    411.873245 | Ferran Sayol                                                                                                                                                                         |
| 508 |    227.658676 |    720.580590 | Matt Crook                                                                                                                                                                           |
| 509 |    237.611629 |    355.064215 | Michelle Site                                                                                                                                                                        |
| 510 |    328.309376 |     20.223677 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 511 |    528.515350 |    323.011850 | Steven Traver                                                                                                                                                                        |
| 512 |   1011.437286 |     51.288912 | NA                                                                                                                                                                                   |
| 513 |    490.224075 |    269.321046 | NA                                                                                                                                                                                   |
| 514 |    257.147673 |     30.880676 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 515 |     43.059053 |    474.014402 | Matt Crook                                                                                                                                                                           |
| 516 |    694.045053 |    718.706704 | Scott Hartman                                                                                                                                                                        |
| 517 |     39.334604 |    772.142823 | Birgit Lang                                                                                                                                                                          |
| 518 |     24.876559 |    314.338433 | Daniel Stadtmauer                                                                                                                                                                    |
| 519 |    295.266573 |     44.360051 | NA                                                                                                                                                                                   |
| 520 |    266.508408 |    583.036134 | Matt Crook                                                                                                                                                                           |
| 521 |    836.857249 |     67.759903 | Martin R. Smith                                                                                                                                                                      |
| 522 |    553.179311 |    141.324424 | Matt Crook                                                                                                                                                                           |
| 523 |    142.284963 |    386.267856 | Kai R. Caspar                                                                                                                                                                        |
| 524 |    972.723771 |    136.365331 | Chris huh                                                                                                                                                                            |
| 525 |   1008.765264 |    488.325648 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                               |
| 526 |    807.338418 |     83.145565 | Caleb M. Brown                                                                                                                                                                       |
| 527 |    395.037026 |    209.633995 | Ferran Sayol                                                                                                                                                                         |
| 528 |    235.924551 |    646.579110 | B Kimmel                                                                                                                                                                             |
| 529 |    739.145575 |    648.833673 | Sarah Alewijnse                                                                                                                                                                      |
| 530 |    831.251748 |    561.521751 | Beth Reinke                                                                                                                                                                          |
| 531 |    810.275929 |    558.181978 | Gareth Monger                                                                                                                                                                        |
| 532 |    169.293512 |    459.414210 | xgirouxb                                                                                                                                                                             |
| 533 |    208.342720 |    214.008769 | Margot Michaud                                                                                                                                                                       |
| 534 |    716.628511 |    198.786429 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 535 |    695.250743 |     41.013197 | Pete Buchholz                                                                                                                                                                        |
| 536 |    424.884379 |    276.112700 | T. Michael Keesey (after Kukalová)                                                                                                                                                   |
| 537 |    601.051704 |    204.275680 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 538 |    732.298069 |    276.630532 | Margot Michaud                                                                                                                                                                       |
| 539 |    677.749505 |    206.256657 | Chris huh                                                                                                                                                                            |
| 540 |     49.209656 |    422.106992 | Gareth Monger                                                                                                                                                                        |
| 541 |    376.386129 |    351.633116 | Margot Michaud                                                                                                                                                                       |
| 542 |    444.271140 |    143.629061 | Margot Michaud                                                                                                                                                                       |
| 543 |    793.574170 |    537.588242 | Matt Crook                                                                                                                                                                           |
| 544 |    673.089635 |    363.313088 | Zimices                                                                                                                                                                              |
| 545 |    314.460831 |    250.985174 | Duane Raver/USFWS                                                                                                                                                                    |
| 546 |    650.955972 |    532.975990 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 547 |    634.453744 |    619.581431 | Scott Reid                                                                                                                                                                           |
| 548 |    533.741551 |    554.526409 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 549 |    259.794654 |    424.982730 | Zimices                                                                                                                                                                              |
| 550 |    411.189022 |    216.378758 | Yan Wong                                                                                                                                                                             |
| 551 |    266.090463 |    101.654811 | Scott Hartman                                                                                                                                                                        |
| 552 |    113.477393 |    646.863906 | Julia B McHugh                                                                                                                                                                       |
| 553 |    911.379621 |    204.897640 | RS                                                                                                                                                                                   |
| 554 |    505.297911 |      3.988184 | Markus A. Grohme                                                                                                                                                                     |
| 555 |    736.750334 |    464.501827 | Steven Traver                                                                                                                                                                        |
| 556 |    553.923285 |    581.908856 | Markus A. Grohme                                                                                                                                                                     |
| 557 |    387.826011 |    788.503845 | Matt Crook                                                                                                                                                                           |
| 558 |    530.149203 |    479.914892 | NA                                                                                                                                                                                   |
| 559 |    516.942893 |    194.970482 | Oscar Sanisidro                                                                                                                                                                      |
| 560 |    733.955356 |    306.460681 | Shyamal                                                                                                                                                                              |
| 561 |    486.696477 |    628.510204 | Ferran Sayol                                                                                                                                                                         |
| 562 |    542.410971 |    770.760829 | NA                                                                                                                                                                                   |
| 563 |    391.556596 |    247.528119 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                                      |
| 564 |    339.632538 |    442.548784 | Matt Crook                                                                                                                                                                           |
| 565 |    733.903512 |    595.190928 | NA                                                                                                                                                                                   |
| 566 |    739.396196 |    780.540802 | Chris huh                                                                                                                                                                            |
| 567 |    749.085550 |    713.744085 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                                             |
| 568 |    272.300612 |     52.661459 | NA                                                                                                                                                                                   |
| 569 |    985.572003 |    110.477363 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 570 |    240.784661 |    738.383236 | Ferran Sayol                                                                                                                                                                         |
| 571 |    105.477370 |     72.303113 | Felix Vaux                                                                                                                                                                           |
| 572 |    547.146208 |    687.374519 | Zimices                                                                                                                                                                              |
| 573 |    247.282038 |     30.166449 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                                            |
| 574 |    880.344487 |    122.643571 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 575 |    548.199914 |    597.108087 | Kamil S. Jaron                                                                                                                                                                       |
| 576 |    525.417431 |    683.716580 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 577 |    807.853703 |    790.801083 | Tracy A. Heath                                                                                                                                                                       |
| 578 |    746.429744 |    574.187793 | Margot Michaud                                                                                                                                                                       |
| 579 |    197.937425 |    423.071967 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
| 580 |    299.133491 |    125.660720 | Iain Reid                                                                                                                                                                            |
| 581 |    466.851470 |    211.965500 | Gareth Monger                                                                                                                                                                        |
| 582 |    773.799472 |    472.548095 | FunkMonk (Michael B. H.)                                                                                                                                                             |
| 583 |    883.306660 |     63.423612 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
| 584 |    670.307749 |     63.233862 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
| 585 |    473.248496 |    677.229983 | Fernando Campos De Domenico                                                                                                                                                          |
| 586 |     29.629063 |    354.832618 | Adrian Reich                                                                                                                                                                         |
| 587 |    619.435802 |    600.739987 | Jagged Fang Designs                                                                                                                                                                  |
| 588 |     21.698147 |      6.067365 | Margot Michaud                                                                                                                                                                       |
| 589 |    271.222832 |    368.304391 | Anthony Caravaggi                                                                                                                                                                    |
| 590 |    889.046175 |    210.458306 | Collin Gross                                                                                                                                                                         |
| 591 |    572.582329 |    306.474170 | Tasman Dixon                                                                                                                                                                         |
| 592 |    625.440201 |     19.801657 | Scott Hartman                                                                                                                                                                        |
| 593 |    615.103770 |    393.606306 | Birgit Lang                                                                                                                                                                          |
| 594 |    854.111211 |    762.095796 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                      |
| 595 |    303.362650 |    415.931751 | Dean Schnabel                                                                                                                                                                        |
| 596 |      9.445159 |    227.071006 | NA                                                                                                                                                                                   |
| 597 |    288.187427 |    198.321286 | Melissa Broussard                                                                                                                                                                    |
| 598 |    204.394465 |     90.974473 | Matthew E. Clapham                                                                                                                                                                   |
| 599 |    995.244590 |     63.883656 | Michael Scroggie                                                                                                                                                                     |
| 600 |   1001.333166 |    136.068079 | Zimices                                                                                                                                                                              |
| 601 |    868.633565 |    788.847715 | Markus A. Grohme                                                                                                                                                                     |
| 602 |    917.260934 |     98.959847 | Zimices                                                                                                                                                                              |
| 603 |    172.921106 |    418.466451 | Matt Crook                                                                                                                                                                           |
| 604 |    573.757337 |    260.123559 | Shyamal                                                                                                                                                                              |
| 605 |    380.168168 |    179.042912 | Zimices, based in Mauricio Antón skeletal                                                                                                                                            |
| 606 |    528.401022 |    264.142294 | Margot Michaud                                                                                                                                                                       |
| 607 |    348.456987 |    281.313066 | Zimices                                                                                                                                                                              |
| 608 |    373.007122 |    489.131847 | Zimices                                                                                                                                                                              |
| 609 |    604.812459 |     80.263214 | FunkMonk                                                                                                                                                                             |
| 610 |    764.893095 |    657.499004 | Kai R. Caspar                                                                                                                                                                        |
| 611 |    325.837629 |    430.202642 | Markus A. Grohme                                                                                                                                                                     |
| 612 |     99.025169 |      7.816758 | Emma Hughes                                                                                                                                                                          |
| 613 |    780.019675 |    358.461896 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 614 |    508.110354 |    256.006385 | Richard Ruggiero, vectorized by Zimices                                                                                                                                              |
| 615 |    280.177745 |    115.390701 | Gareth Monger                                                                                                                                                                        |
| 616 |    358.981709 |    158.178826 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                        |
| 617 |     78.606762 |    730.099989 | Jessica Anne Miller                                                                                                                                                                  |
| 618 |    410.719360 |    584.140491 | Markus A. Grohme                                                                                                                                                                     |
| 619 |    902.798480 |     99.489960 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 620 |    772.739077 |    100.801423 | Matt Crook                                                                                                                                                                           |
| 621 |     42.725688 |    667.527943 | NA                                                                                                                                                                                   |
| 622 |    186.222363 |    323.087972 | Mo Hassan                                                                                                                                                                            |
| 623 |    405.184917 |    546.600247 | Zimices                                                                                                                                                                              |
| 624 |    282.616230 |    506.372013 | NA                                                                                                                                                                                   |
| 625 |    607.504979 |    527.093277 | Zimices                                                                                                                                                                              |
| 626 |    873.242198 |    191.702011 | Gareth Monger                                                                                                                                                                        |
| 627 |    430.542667 |    410.661928 | Sarah Werning                                                                                                                                                                        |
| 628 |    580.838000 |    525.409073 | Agnello Picorelli                                                                                                                                                                    |
| 629 |    984.134058 |     54.862000 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 630 |    614.428180 |    346.144418 | Kamil S. Jaron                                                                                                                                                                       |
| 631 |    683.890059 |    406.617459 | Gareth Monger                                                                                                                                                                        |
| 632 |    218.908929 |    621.856193 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 633 |    480.862532 |    270.211150 | Dinah Challen                                                                                                                                                                        |
| 634 |    717.600040 |    152.755117 | T. Michael Keesey                                                                                                                                                                    |
| 635 |    861.123504 |    260.713071 | Tasman Dixon                                                                                                                                                                         |
| 636 |    814.591468 |    102.357765 | Margot Michaud                                                                                                                                                                       |
| 637 |    869.644794 |    166.357023 | Ferran Sayol                                                                                                                                                                         |
| 638 |    568.004279 |    253.022910 | Chris huh                                                                                                                                                                            |
| 639 |    758.382242 |    680.463967 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                                      |
| 640 |    914.182411 |    327.300005 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                                |
| 641 |    783.420143 |    554.400693 | M Kolmann                                                                                                                                                                            |
| 642 |    319.196575 |    304.036697 | Michelle Site                                                                                                                                                                        |
| 643 |    586.053464 |    371.573890 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
| 644 |     92.555736 |    657.707657 | Pedro de Siracusa                                                                                                                                                                    |
| 645 |   1011.051408 |    766.981231 | NA                                                                                                                                                                                   |
| 646 |    396.414078 |    351.185939 | Bob Goldstein, Vectorization:Jake Warner                                                                                                                                             |
| 647 |    777.049011 |     58.148944 | Collin Gross                                                                                                                                                                         |
| 648 |    955.844203 |    110.863211 | Chris huh                                                                                                                                                                            |
| 649 |    678.015753 |    644.413775 | Matt Crook                                                                                                                                                                           |
| 650 |     84.273512 |    635.505867 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 651 |     92.472824 |    178.200773 | Matt Crook                                                                                                                                                                           |
| 652 |   1015.719506 |    616.412289 | Ferran Sayol                                                                                                                                                                         |
| 653 |    747.289403 |    424.800123 | Mario Quevedo                                                                                                                                                                        |
| 654 |    641.590112 |    377.878254 | Ferran Sayol                                                                                                                                                                         |
| 655 |    355.286423 |    336.645819 | Margot Michaud                                                                                                                                                                       |
| 656 |     20.314257 |     64.212704 | Michele Tobias                                                                                                                                                                       |
| 657 |    542.134557 |    675.008528 | Steven Coombs                                                                                                                                                                        |
| 658 |    649.035649 |    738.345317 | Scott Hartman                                                                                                                                                                        |
| 659 |    547.466149 |    190.180443 | Ferran Sayol                                                                                                                                                                         |
| 660 |    222.687721 |    790.900660 | Steven Traver                                                                                                                                                                        |
| 661 |    193.273970 |    199.199052 | Iain Reid                                                                                                                                                                            |
| 662 |     69.418452 |    768.949671 | Tauana J. Cunha                                                                                                                                                                      |
| 663 |   1016.415947 |    719.181780 | Mathilde Cordellier                                                                                                                                                                  |
| 664 |    767.062882 |    496.235000 | Matt Crook                                                                                                                                                                           |
| 665 |    577.248372 |    423.116598 | T. Michael Keesey                                                                                                                                                                    |
| 666 |     19.855550 |    750.207763 | Steven Coombs                                                                                                                                                                        |
| 667 |    475.601917 |     16.049650 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 668 |    973.853960 |     22.568258 | Chris huh                                                                                                                                                                            |
| 669 |    135.024220 |    118.804194 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                                           |
| 670 |    327.840003 |    776.537934 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 671 |   1011.684392 |    649.284507 | Ferran Sayol                                                                                                                                                                         |
| 672 |    430.417612 |      8.360572 | Matt Crook                                                                                                                                                                           |
| 673 |    301.528192 |    682.526424 | Scott Hartman                                                                                                                                                                        |
| 674 |   1013.515056 |    111.699630 | Matt Crook                                                                                                                                                                           |
| 675 |     18.366166 |    134.405347 | Tauana J. Cunha                                                                                                                                                                      |
| 676 |    890.403317 |    748.829731 | Jagged Fang Designs                                                                                                                                                                  |
| 677 |    968.300350 |     81.361656 | Lukas Panzarin                                                                                                                                                                       |
| 678 |    243.316979 |    546.905391 | Tracy A. Heath                                                                                                                                                                       |
| 679 |    322.878692 |    278.290179 | Lafage                                                                                                                                                                               |
| 680 |    554.035616 |    454.867557 | Mo Hassan                                                                                                                                                                            |
| 681 |    512.542548 |    488.443023 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 682 |    320.391140 |    505.158752 | Margot Michaud                                                                                                                                                                       |
| 683 |    414.693942 |    390.362716 | Crystal Maier                                                                                                                                                                        |
| 684 |    526.063992 |    286.606894 | Andrew A. Farke                                                                                                                                                                      |
| 685 |    547.680579 |    521.747719 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                                                   |
| 686 |    223.775858 |     20.779491 | Scott Hartman                                                                                                                                                                        |
| 687 |    519.342331 |    105.948551 | Chris huh                                                                                                                                                                            |
| 688 |   1020.782361 |    491.788894 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 689 |    555.471338 |    150.248780 | Collin Gross                                                                                                                                                                         |
| 690 |    969.510897 |    403.399824 | Steven Traver                                                                                                                                                                        |
| 691 |    676.775348 |    740.234024 | Jaime Headden                                                                                                                                                                        |
| 692 |    601.204348 |    433.981835 | Pete Buchholz                                                                                                                                                                        |
| 693 |    561.550821 |    589.726985 | Matt Crook                                                                                                                                                                           |
| 694 |    731.983159 |    715.722967 | Michael Scroggie                                                                                                                                                                     |
| 695 |    497.851707 |    603.758427 | NA                                                                                                                                                                                   |
| 696 |    561.786702 |    572.350245 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                                           |
| 697 |    944.380070 |    168.725917 | Terpsichores                                                                                                                                                                         |
| 698 |    888.064682 |    722.797962 | Chuanixn Yu                                                                                                                                                                          |
| 699 |     88.338004 |    584.357904 | Zimices                                                                                                                                                                              |
| 700 |    935.316959 |    397.041480 | Tasman Dixon                                                                                                                                                                         |
| 701 |    190.580697 |    701.788791 | Margot Michaud                                                                                                                                                                       |
| 702 |    242.468340 |    160.146654 | Auckland Museum                                                                                                                                                                      |
| 703 |     12.107317 |    239.323051 | Zimices                                                                                                                                                                              |
| 704 |    163.879102 |    519.343266 | Chris huh                                                                                                                                                                            |
| 705 |    846.320383 |    430.202386 | Collin Gross                                                                                                                                                                         |
| 706 |    372.915863 |     54.159521 | Emily Willoughby                                                                                                                                                                     |
| 707 |    116.657017 |    572.280610 | Gareth Monger                                                                                                                                                                        |
| 708 |    130.458621 |    157.742153 | NA                                                                                                                                                                                   |
| 709 |    916.437749 |    319.216555 | NA                                                                                                                                                                                   |
| 710 |    634.346410 |    228.485252 | Margot Michaud                                                                                                                                                                       |
| 711 |    240.831595 |    503.425679 | Chris huh                                                                                                                                                                            |
| 712 |     69.958181 |    223.383885 | Margot Michaud                                                                                                                                                                       |
| 713 |    618.814475 |    372.448430 | Margot Michaud                                                                                                                                                                       |
| 714 |    555.923453 |    302.582330 | Chris huh                                                                                                                                                                            |
| 715 |    964.895580 |    321.819315 | Steven Traver                                                                                                                                                                        |
| 716 |    357.807142 |    465.485501 | NASA                                                                                                                                                                                 |
| 717 |    146.000068 |    526.537032 | Matt Crook                                                                                                                                                                           |
| 718 |    696.659004 |    356.026078 | Margot Michaud                                                                                                                                                                       |
| 719 |    530.136169 |    189.914749 | Margot Michaud                                                                                                                                                                       |
| 720 |    595.406636 |    474.778035 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                                       |
| 721 |    775.663383 |    126.424838 | Taro Maeda                                                                                                                                                                           |
| 722 |    756.964123 |    552.636100 | Rebecca Groom                                                                                                                                                                        |
| 723 |    355.393792 |    136.415738 | Alex Slavenko                                                                                                                                                                        |
| 724 |    270.877076 |    658.636517 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 725 |    470.247016 |    443.104257 | NA                                                                                                                                                                                   |
| 726 |    932.122647 |    520.168855 | Jagged Fang Designs                                                                                                                                                                  |
| 727 |    796.765710 |    438.504382 | Anthony Caravaggi                                                                                                                                                                    |
| 728 |    702.506730 |    242.762731 | Gareth Monger                                                                                                                                                                        |
| 729 |    996.529983 |    480.434048 | Martin R. Smith                                                                                                                                                                      |
| 730 |    313.339371 |    573.549562 | Gareth Monger                                                                                                                                                                        |
| 731 |    748.920648 |    162.615943 | Chris Hay                                                                                                                                                                            |
| 732 |    292.370910 |    561.660094 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 733 |    221.839752 |    776.537690 | S.Martini                                                                                                                                                                            |
| 734 |    421.188717 |    596.918426 | Jagged Fang Designs                                                                                                                                                                  |
| 735 |    770.633608 |    244.913111 | NA                                                                                                                                                                                   |
| 736 |    159.535243 |    345.989275 | Raven Amos                                                                                                                                                                           |
| 737 |    897.583464 |    282.068816 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 738 |    170.213354 |    128.061539 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 739 |    456.238513 |    697.775253 | Markus A. Grohme                                                                                                                                                                     |
| 740 |    993.699298 |    636.446217 | Steven Traver                                                                                                                                                                        |
| 741 |    469.355781 |    794.656925 | NA                                                                                                                                                                                   |
| 742 |    443.087200 |    118.975189 | NA                                                                                                                                                                                   |
| 743 |    270.200018 |    720.557809 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 744 |    207.079635 |    235.643000 | Andrew A. Farke                                                                                                                                                                      |
| 745 |    360.604833 |    250.228209 | Gareth Monger                                                                                                                                                                        |
| 746 |    530.063841 |    294.406179 | Becky Barnes                                                                                                                                                                         |
| 747 |    381.700682 |    239.028534 | Anthony Caravaggi                                                                                                                                                                    |
| 748 |    292.779427 |    165.305655 | Matt Wilkins                                                                                                                                                                         |
| 749 |      9.491165 |    626.734315 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 750 |   1005.565941 |    585.377931 | Jagged Fang Designs                                                                                                                                                                  |
| 751 |    594.454587 |    496.779775 | CNZdenek                                                                                                                                                                             |
| 752 |    284.284090 |    372.016732 | Tracy A. Heath                                                                                                                                                                       |
| 753 |    551.048256 |    238.394869 | Lukasiniho                                                                                                                                                                           |
| 754 |    253.656761 |    364.560604 | Andrew A. Farke                                                                                                                                                                      |
| 755 |    983.525091 |     41.645496 | Manabu Sakamoto                                                                                                                                                                      |
| 756 |    999.001075 |     19.961639 | Sarah Werning                                                                                                                                                                        |
| 757 |    760.682366 |    598.117948 | Jagged Fang Designs                                                                                                                                                                  |
| 758 |      9.714595 |    144.069430 | Tasman Dixon                                                                                                                                                                         |
| 759 |    563.456559 |    131.598968 | Birgit Lang                                                                                                                                                                          |
| 760 |    554.453150 |    776.539349 | Dean Schnabel                                                                                                                                                                        |
| 761 |    968.126889 |     68.740910 | Jagged Fang Designs                                                                                                                                                                  |
| 762 |    986.456534 |    563.654312 | Cristina Guijarro                                                                                                                                                                    |
| 763 |    888.318460 |    338.678343 | Juan Carlos Jerí                                                                                                                                                                     |
| 764 |    124.170534 |     63.119338 | Iain Reid                                                                                                                                                                            |
| 765 |    603.650253 |    299.507868 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 766 |    454.996907 |    354.881960 | T. Michael Keesey                                                                                                                                                                    |
| 767 |     22.382202 |    363.267505 | Jagged Fang Designs                                                                                                                                                                  |
| 768 |    565.119415 |    520.941375 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                                |
| 769 |    478.012293 |    689.067393 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                                                   |
| 770 |    605.915203 |    419.669856 | Matt Crook                                                                                                                                                                           |
| 771 |    514.772249 |     91.286591 | Gareth Monger                                                                                                                                                                        |
| 772 |    210.684881 |    591.897910 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 773 |    635.230211 |    305.228867 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 774 |    912.419604 |      3.712629 | Milton Tan                                                                                                                                                                           |
| 775 |    471.928856 |    197.662793 | Lauren Sumner-Rooney                                                                                                                                                                 |
| 776 |    152.905173 |     91.769733 | Chris huh                                                                                                                                                                            |
| 777 |    489.443605 |    117.987464 | Kamil S. Jaron                                                                                                                                                                       |
| 778 |    649.133482 |    791.957299 | Chuanixn Yu                                                                                                                                                                          |
| 779 |     34.311839 |    783.919091 | FunkMonk                                                                                                                                                                             |
| 780 |    301.844664 |     51.545876 | Tasman Dixon                                                                                                                                                                         |
| 781 |    461.183562 |    150.298275 | Maija Karala                                                                                                                                                                         |
| 782 |    726.019133 |     19.253339 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 783 |    536.479430 |     90.120330 | Baheerathan Murugavel                                                                                                                                                                |
| 784 |    812.871213 |    120.291181 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 785 |    229.637557 |    533.612160 | \<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\> (vectorized by T. Michael Keesey)                                                         |
| 786 |    327.300570 |    163.859195 | T. Michael Keesey                                                                                                                                                                    |
| 787 |    248.402663 |     77.992193 | Ferran Sayol                                                                                                                                                                         |
| 788 |    399.736426 |    259.690135 | Matt Crook                                                                                                                                                                           |
| 789 |    765.676691 |    559.593260 | Tasman Dixon                                                                                                                                                                         |
| 790 |    399.777701 |    593.551147 | Matt Crook                                                                                                                                                                           |
| 791 |    449.719470 |    647.060655 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 792 |    176.029843 |    680.817272 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 793 |    724.209685 |    364.991592 | Michele M Tobias                                                                                                                                                                     |
| 794 |    157.200305 |     41.288095 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 795 |    924.561557 |    722.739905 | Chuanixn Yu                                                                                                                                                                          |
| 796 |    326.913880 |    528.203985 | FunkMonk                                                                                                                                                                             |
| 797 |    803.205392 |    412.746975 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                                     |
| 798 |    946.824977 |    535.393735 | Jaime Headden, modified by T. Michael Keesey                                                                                                                                         |
| 799 |    295.481758 |    181.946238 | Gareth Monger                                                                                                                                                                        |
| 800 |    773.173366 |    568.956093 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 801 |    868.335411 |    605.774279 | Ferran Sayol                                                                                                                                                                         |
| 802 |    379.479375 |    216.236745 | Matt Crook                                                                                                                                                                           |
| 803 |    162.997454 |    774.557038 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                                                  |
| 804 |    750.692038 |    607.874272 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 805 |   1007.033629 |    555.056295 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                                             |
| 806 |    970.463921 |     62.490138 | Jagged Fang Designs                                                                                                                                                                  |
| 807 |    614.026860 |    652.849839 | NA                                                                                                                                                                                   |
| 808 |      7.566122 |    374.340565 | Gareth Monger                                                                                                                                                                        |
| 809 |    811.931403 |    473.538397 | Scott Hartman                                                                                                                                                                        |
| 810 |    189.553814 |     70.868932 | Margot Michaud                                                                                                                                                                       |
| 811 |    563.612603 |    405.684949 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                                           |
| 812 |    443.145181 |    583.083208 | Steven Traver                                                                                                                                                                        |
| 813 |    336.637930 |    521.177977 | Jagged Fang Designs                                                                                                                                                                  |
| 814 |    812.081869 |    422.317801 | Matt Crook                                                                                                                                                                           |
| 815 |    290.671466 |    747.581284 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                                           |
| 816 |    502.440165 |    269.424054 | Beth Reinke                                                                                                                                                                          |
| 817 |    780.573542 |    113.148705 | Zimices                                                                                                                                                                              |
| 818 |    775.324141 |    189.907207 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                                    |
| 819 |    118.537131 |     79.090920 | Michelle Site                                                                                                                                                                        |
| 820 |    412.686833 |    721.624389 | Gareth Monger                                                                                                                                                                        |
| 821 |    963.154189 |    298.364069 | NA                                                                                                                                                                                   |
| 822 |    494.420567 |    149.570807 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 823 |    873.320322 |    214.319086 | Y. de Hoev. (vectorized by T. Michael Keesey)                                                                                                                                        |
| 824 |    145.655985 |    726.431212 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 825 |    975.600287 |    307.482832 | Steven Traver                                                                                                                                                                        |
| 826 |    169.824747 |    507.541504 | terngirl                                                                                                                                                                             |
| 827 |    402.050244 |      5.220036 | E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael Keesey)                                                                                                 |
| 828 |    157.439275 |    782.509073 | Zimices                                                                                                                                                                              |
| 829 |    426.951862 |    191.390059 | Noah Schlottman, photo by Antonio Guillén                                                                                                                                            |
| 830 |   1001.098961 |    449.223858 | Tasman Dixon                                                                                                                                                                         |
| 831 |    942.057942 |    470.767209 | Michael P. Taylor                                                                                                                                                                    |
| 832 |    475.318548 |    458.412491 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                                                       |
| 833 |    523.835528 |    533.086926 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                                        |
| 834 |     10.998713 |    302.565812 | Steven Traver                                                                                                                                                                        |
| 835 |    908.474914 |    106.017588 | Ignacio Contreras                                                                                                                                                                    |
| 836 |    598.214013 |    537.113708 | Margot Michaud                                                                                                                                                                       |
| 837 |    584.106251 |    709.192988 | Scott Reid                                                                                                                                                                           |
| 838 |    399.190474 |    470.683890 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                                    |
| 839 |    999.605568 |    468.787080 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 840 |    843.715250 |    782.768231 | Ludwik Gasiorowski                                                                                                                                                                   |
| 841 |    604.477138 |    777.823660 | Taro Maeda                                                                                                                                                                           |
| 842 |    838.113352 |    287.973591 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 843 |    630.798676 |     90.255816 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 844 |    151.775201 |    298.956904 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 845 |    188.745670 |    550.365760 | Beth Reinke                                                                                                                                                                          |
| 846 |    994.207592 |    650.258183 | Jennifer Trimble                                                                                                                                                                     |
| 847 |    580.644062 |    285.618657 | Jaime Headden                                                                                                                                                                        |
| 848 |    128.266953 |    485.519342 | Melissa Broussard                                                                                                                                                                    |
| 849 |    418.441552 |    541.230373 | NA                                                                                                                                                                                   |
| 850 |     33.265126 |    742.914927 | Kai R. Caspar                                                                                                                                                                        |
| 851 |    960.420567 |    543.192655 | Gareth Monger                                                                                                                                                                        |
| 852 |    638.337826 |     65.937103 | Harold N Eyster                                                                                                                                                                      |
| 853 |    302.486195 |    674.711736 | Alexandra van der Geer                                                                                                                                                               |
| 854 |   1014.617395 |    545.462469 | Matt Crook                                                                                                                                                                           |
| 855 |    885.347175 |    185.007760 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                                |
| 856 |    304.296152 |    725.439203 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                                           |
| 857 |    752.171987 |    654.122505 | Matt Crook                                                                                                                                                                           |
| 858 |    552.971865 |    259.978813 | NA                                                                                                                                                                                   |
| 859 |    240.491113 |    660.550482 | Yan Wong                                                                                                                                                                             |
| 860 |    444.775121 |    442.044450 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                                        |
| 861 |    713.601441 |    734.825913 | Ingo Braasch                                                                                                                                                                         |
| 862 |    534.108348 |    125.246280 | Steven Traver                                                                                                                                                                        |
| 863 |    708.295143 |    722.272486 | Chris huh                                                                                                                                                                            |
| 864 |    755.749712 |    584.770360 | Caleb M. Brown                                                                                                                                                                       |
| 865 |    993.816080 |    225.930731 | Javier Luque                                                                                                                                                                         |
| 866 |    209.099073 |    479.795094 | Matt Crook                                                                                                                                                                           |
| 867 |     32.684776 |     76.840246 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 868 |    599.717803 |    789.838077 | Nobu Tamura                                                                                                                                                                          |
| 869 |    203.925826 |    764.266334 | Scott Hartman                                                                                                                                                                        |
| 870 |     10.613342 |     50.762491 | Tasman Dixon                                                                                                                                                                         |
| 871 |    708.798450 |    307.643993 | Arthur S. Brum                                                                                                                                                                       |
| 872 |    286.488503 |    131.556636 | T. Michael Keesey                                                                                                                                                                    |
| 873 |     95.972964 |    621.490549 | Smokeybjb, vectorized by Zimices                                                                                                                                                     |
| 874 |    227.649419 |    192.413174 | Katie S. Collins                                                                                                                                                                     |
| 875 |   1008.035091 |    122.519234 | Gareth Monger                                                                                                                                                                        |
| 876 |    915.627493 |    217.243658 | Jimmy Bernot                                                                                                                                                                         |
| 877 |    520.435659 |    614.873991 | Zimices                                                                                                                                                                              |
| 878 |    932.515260 |     73.890314 | Dean Schnabel                                                                                                                                                                        |
| 879 |    853.490377 |    712.659610 | Myriam\_Ramirez                                                                                                                                                                      |
| 880 |    586.554824 |    766.192803 | NA                                                                                                                                                                                   |
| 881 |    703.550931 |    231.492839 | Steven Coombs                                                                                                                                                                        |
| 882 |    424.631278 |    745.239154 | Margot Michaud                                                                                                                                                                       |
| 883 |    408.520677 |    401.418835 | Margot Michaud                                                                                                                                                                       |
| 884 |    716.395247 |    354.194535 | S.Martini                                                                                                                                                                            |
| 885 |    515.312352 |    285.500544 | Gareth Monger                                                                                                                                                                        |
| 886 |    947.432901 |     83.882876 | Margot Michaud                                                                                                                                                                       |
| 887 |   1011.681746 |    741.990174 | Gareth Monger                                                                                                                                                                        |
| 888 |    146.608528 |    375.481295 | Chuanixn Yu                                                                                                                                                                          |
| 889 |    729.137875 |    527.932733 | Matt Crook                                                                                                                                                                           |
| 890 |    453.665031 |    545.283057 | Steven Traver                                                                                                                                                                        |
| 891 |    708.735215 |    642.013100 | Griensteidl and T. Michael Keesey                                                                                                                                                    |
| 892 |    505.833569 |     50.187238 | Katie S. Collins                                                                                                                                                                     |
| 893 |     38.535034 |    109.308449 | DW Bapst (modified from Bulman, 1970)                                                                                                                                                |
| 894 |    651.837110 |    112.815810 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                                   |
| 895 |    947.669241 |    457.743440 | Chris huh                                                                                                                                                                            |
| 896 |    327.916368 |    461.264146 | Dmitry Bogdanov                                                                                                                                                                      |
| 897 |     47.632412 |    220.114629 | Matt Crook                                                                                                                                                                           |
| 898 |    345.106654 |    101.840473 | Steven Traver                                                                                                                                                                        |
| 899 |    210.196318 |    160.583277 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                                |
| 900 |    160.923282 |    446.569415 | Melissa Broussard                                                                                                                                                                    |
| 901 |     18.071440 |    339.877863 | Julio Garza                                                                                                                                                                          |
| 902 |    352.356717 |    302.115927 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 903 |    725.867401 |    778.890646 | Matt Crook                                                                                                                                                                           |
| 904 |    603.364892 |    584.912326 | Margot Michaud                                                                                                                                                                       |
| 905 |    432.830566 |    796.848717 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                     |
| 906 |    653.403597 |    319.952829 | Matt Crook                                                                                                                                                                           |
| 907 |    585.362948 |    194.642957 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                                    |
| 908 |    918.947643 |    147.449705 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 909 |   1009.748255 |    376.280823 | Tyler Greenfield                                                                                                                                                                     |
| 910 |    758.629035 |    614.994924 | T. Michael Keesey                                                                                                                                                                    |
| 911 |   1004.460562 |    726.848842 | Gareth Monger                                                                                                                                                                        |

    #> Your tweet has been posted!
