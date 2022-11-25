FROM opensuse/tumbleweed

RUN zypper --non-interactive dup
RUN zypper --non-interactive in find createrepo
COPY docker/mkrepo.sh /usr/libexec
CMD ["bash", "/usr/libexec/mkrepo.sh"]
