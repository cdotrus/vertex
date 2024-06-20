# Project: Vertex
# Module: vectors
#
# A Vectors contains the test vectors for a particular model.

from . import context

class Vectors:
    from .model import Mode
    from typing import List as _List

    def __init__(self, path: str, mode: Mode, order: _List[str]=None):
        '''
        Creates a trace file to write stimuli/results for a potential hardware simulation.
        
        ### Parameters
        - The `name` argument sets the file's path name
        - The `mode` argument determines which directional ports to capture when writing to the file.
        - The `order` argument is the list of port names to write. It must include all ports that match the direction
        set by `mode`. This list determines the order in which to serialize the data when writing traces. If omitted,
        the port order is determined by the order found in the HDL top-level port interface.
        '''
        import os
        from .model import Mode

        self._path = str(path)
        # try to decode str if provided as a string
        self._mode = mode if isinstance(mode, Mode) == True else Mode.from_str(str(mode))

        self._exists = os.path.exists(self._path)
        # clear the existing file
        if self._exists == True:
            open(self._path, 'w').close()
        # create the file if it does not exist
        elif self._exists == False:
            if len(os.path.dirname(self._path)) > 0:
                os.makedirs(os.path.dirname(self._path), exist_ok=True)
            open(self._path, 'w').close()
            self._exists = True

        self._file = None
        pass


    def __del__(self):
        if self._file != None:
            self._file.close()
        pass


    def __enter__(self):
        if self._file == None:
            self._file = open(self._path, 'a')
        return self
    

    def __exit__(self, exception_type, exception_value, exception_traceback):
        # handle any exccpetions
        self._file.close()


    def open(self):
        '''
        Explicit call to obtain ownership of the file. It is the programmer's
        responsibility to close the file when done.

        Calling this function and leaving the file open while appending traces
        to the test vector files can improve performance when many writes are
        required.
        '''
        # open the file in append mode
        if self._file == None:
            self._file = open(self._path, 'a')
        return self
    

    def close(self):
        '''
        Explicit call to release ownership of the file. This operation is
        idempotent.
        '''
        if self._file != None:
            self._file.close()
            self._file = None
        return self


    def append(self, model):
        '''
        Writes the directional ports of the bus funcitonal model to the test vector file.

        Format each signal as logic values in the file to be read in during
        simulation.

        The format uses commas (`,`) to separate different signals and the order of signals
        written matches the order of ports in the interface json data.

        Each value is written with a ',' after the preceeding value in the 
        argument list. A newline is formed after all arguments
        '''
        from .model import Signal, _extract_ports
        from .coverage import CoverageNet, Coverage

        if self._file == None:
            raise Exception("failed to write to file " + str(self._path) + " due to not being open")
        
        info: Signal
        net: CoverageNet

        # ignore the name when collecting the ports for the given mode
        signals = [p[1] for p in _extract_ports(model, mode=self._mode)]
        # check if there are coverages to automatically update
        for net in Coverage.get_nets():
            if net.has_sink() == True:
                # verify the observation involves only signals being written for this transaction
                sinks = net.get_sink_list()
                for sink in sinks:
                    # exit early if a signal being observed is not this transaction
                    if sink not in signals:
                        break
                    pass
                # perform an observation if the signals are in this transaction
                else:
                    net.cover(net.get_sink())
            pass

        DELIM = ' '
        NEWLINE = '\n'

        open_in_scope: bool = self._file == None
        fd = self._file if open_in_scope == False else open(self._path, 'a')
        
        for info in signals:
            fd.write(str(info) + DELIM)
        fd.write(NEWLINE)
        # close the file if it was opened in this current scope
        if open_in_scope == True:
            fd.close()
        pass

    pass